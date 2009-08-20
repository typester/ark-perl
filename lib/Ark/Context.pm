package Ark::Context;
use Mouse;
use Mouse::Util::TypeConstraints;

use Ark::Request;
use HTTP::Engine::Response;
use Scalar::Util ();

our $DETACH = 'ARK_DETACH';

extends 'Ark::Component';

coerce 'Ark::Request'
    => from 'Object'
    => via {
        $_->isa('Ark::Request') ? $_ : Ark::Request->new(%$_);
    };

has request => (
    is       => 'rw',
    isa      => 'Ark::Request',
    required => 1,
    coerce   => 1,
);

has response => (
    is      => 'rw',
    isa     => 'HTTP::Engine::Response',
    lazy    => 1,
    default => sub {
        HTTP::Engine::Response->new;
    },
);

has app => (
    is       => 'rw',
    isa      => 'Ark::Core',
    required => 1,
    weak_ref => 1,
    handles  => ['debug', 'log', 'get_actions', 'get_action', 'ensure_class_loaded',
                 'component', 'view', 'model', 'path_to', 'config',],
);

has stash => (
    is      => 'rw',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { {} },
);

has stack => (
    is      => 'rw',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub { [] },
);

has state => (
    is      => 'rw',
    default => 0,
);

has error => (
    is      => 'rw',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub { [] },
);

has detached => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

{   # alias
    no warnings 'once';
    *req = \&request;
    *res = \&response;
}

sub process {
    my $self = shift;

    $self->prepare;
    $self->dispatch;
    $self->finalize;
}

sub prepare {
    my $self = shift;

    $self->prepare_action;
    $self->prepare_encoding;
    $self->prepare_headers;
    $self->prepare_body;
}

sub prepare_action {
    my $self = shift;
    my $req  = $self->request;

    my $vpath = $req->uri->rel->path;
    $vpath =~ s!^\.\./[^/]+!!;                    # fix ../foo/path => /path
    $vpath =~ s!^\./!!;                           # fix ./path => /path
    $vpath = '/' . $vpath unless $vpath =~ m!^/!; # path should be / first

    my @path = split /\//, $vpath;
    unshift @path, '' unless @path;

 DESCEND: while (@path) {
        my $path = join '/', @path;
        $path =~ s!^/!!;

        for my $type (@{ $self->app->dispatch_types }) {
            last DESCEND if $type->match( $req, $path );
        }

        my $arg = pop @path;
        $arg =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
        unshift @{ $req->arguments }, $arg;
    }

    s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg
        for grep {defined} @{ $req->captures || [] };
}

sub prepare_headers {}

sub prepare_body {}

sub forward {
    my ($self, $target, @args) = @_;

    return 0 unless $target;

    if (Scalar::Util::blessed($target)) {
        if ($target->isa('Ark::Action')) {
            $target->dispatch($self, @args);
            return $self->state;
        }
        elsif ($target->can('process')) {
            $self->execute($target, 'process', @args);
            return $self->state;
        }
    }
    else {
        if ($target =~ m!^/.+!) {
            my ($namespace, $name) = $target =~ m!^(.*/)([^/]+)$!;
            $namespace =~ s!(^/|/$)!!g;
            if (my $action = $self->get_action($name, $namespace || '')) {
                $action->dispatch($self, @args);
                return $self->state;
            }
        }
        else {
            my $last = $self->stack->[-1];
            if ($last
                 and $last->{obj}->isa('Ark::Controller')
                 and my $action = $self->get_action($target, $last->{obj}->namespace)) {

                $action->dispatch($self, @args);
                return $self->state;
            }
        }
    }

    my $error = qq/Couldn't forward to $target, Invalid action or component/;
    $self->log( error => $error );
    push @{ $self->error }, $error;

    return 0;
}

sub detach {
    shift->forward(@_);
    die $DETACH;
}

sub dispatch {
    my $self = shift;

    my $action = $self->request->action;
    if ($action) {
        $action->dispatch_chain($self);
    }
    else {
        $self->log( error => 'no action found' );
    }
}

sub depth {
    scalar @{ shift->stack };
}

sub execute {
    my ($self, $obj, $method, @args) = @_;
    my $class = ref $obj;

    $self->state(0);
    push @{ $self->stack }, {
        obj       => $obj,
        method    => $method,
        args      => \@args,
        as_string => "${class}->${method}"
    };

    $self->execute_action($obj, $method, @args);

    pop @{ $self->stack };

    if (my $error = $@) {
        if ($error =~ /^${DETACH} at /) {
            die $DETACH if ($self->depth > 1);
            $self->detached(1);
        }
        else {
            push @{ $self->error }, $error;
            $self->state(0);
        }
    }

    $self->state;
}

sub execute_action {
    my ($self, $obj, $method, @args) = @_;

    eval {
        my $state = $obj->$method($self, @args);
        $self->state( defined $state ? $state : undef );
    };
}

sub redirect {
    my ($self, $uri, $status) = @_;

    $status ||= '302';

    $self->res->status($status);
    $self->res->header( Location => $uri );
}

sub redirect_and_detach {
    my $self = shift;
    $self->redirect(@_);
    $self->detach;
}

sub uri_for {
    my ($self, @path) = @_;
    my $params = ref $path[-1] eq 'HASH' ? pop @path : {};

    (my $path = join '/', @path) =~ s!/{2,}!/!g;
    $path =~ s!^/+!!;
    my $uri = URI::WithBase->new($path, $self->req->base);
    $uri->query_form($params);

    $uri->abs;
}

sub finalize {
    my $self = shift;

    $self->finalize_headers;
    $self->finalize_body;
    $self->finalize_encoding;
}

sub finalize_headers {}
sub finalize_body {}

1;

