package Ark::Context;
use Any::Moose;
use Any::Moose '::Util::TypeConstraints';

use Scalar::Util ();
use Try::Tiny;

our $DETACH    = 'ARK_DETACH';
our $DEFERRED  = 'ARK_DEFERRED';
our $STREAMING = 'ARK_STREAMING';

extends 'Ark::Component';

has request => (
    is       => 'rw',
    isa      => 'Object',
    required => 1,
);

has response => (
    is      => 'rw',
    isa     => 'Ark::Response',
    lazy    => 1,
    default => sub {
        my $self = shift;
        Ark::Response->new( context => $self );
    },
);

has app => (
    is       => 'rw',
    isa      => 'Ark::Core',
    required => 1,
    weak_ref => 1,
    handles  => ['debug', 'log', 'get_actions', 'get_action', 'ensure_class_loaded',
                 'component', 'controller', 'view', 'model', 'path_to', 'config',
                 'router',],
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

has [qw/detached finalized/] => (
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
    $self->finalize unless $self->response->is_deferred;
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

    $req->match( $self->router->match($req->path) );
}

sub prepare_headers {}

sub prepare_body {}

sub forward {
    my ($self, $target, @args) = @_;
    return 0 unless $target;

    unless (@args) {
        @args = @{ $self->req->captures } ? @{ $self->req->captures }
                                          : @{ $self->req->args };
    }

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

    my $match = $self->request->match;
    if ($match) {
        $self->dispatch_private_action('begin')
            and $self->dispatch_auto_action
                and $match->dispatch($self);

        $self->detached(0);
        $self->dispatch_private_action('end')
            unless $self->res->is_deferred or $self->res->is_streaming;
    }
    else {
        $self->log( error => 'no action found' );
    }
}

sub dispatch_action {
    my ($self, $name) = @_;

    my $action = ($self->router->get_actions($name, $self->req->action->namespace))[-1]
        or return 1;
    $action->dispatch($self);

    !@{ $self->error };
}

sub dispatch_private_action {
    my ($self, $name) = @_;

    my $action = ($self->router->get_actions($name, $self->req->action->namespace))[-1];
    return 1 unless ($action and $action->attributes->{Private});
    
    $action->dispatch($self);

    !@{ $self->error };
}

sub dispatch_auto_action {
    my $self = shift;

    for my $auto ($self->router->get_actions('auto', $self->req->action->namespace)) {
        next unless $auto->attributes->{Private};
        $auto->dispatch($self);
        return 0 unless $self->state;
    }

    1;
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

    my $error;
    try {
        $self->execute_action($obj, $method, @args);
    } catch {
        $error = $_;
    };

    pop @{ $self->stack };

    if ($error) {
        if ($error =~ /^${DETACH} at /) {
            die $DETACH if ($self->depth >= 1);
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

    my $state = $obj->$method($self, @args);
    $self->state( defined $state ? $state : undef );
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

    my $base = $self->req->base;
    $base =~ s!/*$!!;

    (my $path = join '/', @path) =~ s!/{2,}!/!g;
    $path =~ s!^/+!!;
    my $uri = URI::WithBase->new($path, $base . '/');
    $uri->query_form($params);

    $uri->abs;
}

sub finalize {
    my $self = shift;

    my $is_deferred = $self->response->is_deferred;

    if ($is_deferred) {
        my $action = $self->request->action;
        if ($action) {
            $self->dispatch_private_action('end');
        }
    }

    $self->finalize_headers;
    $self->finalize_body;
    $self->finalize_encoding;
    $self->response->finalize if $self->response->is_deferred;
    $self->finalized(1);
}

sub finalize_headers {}
sub finalize_body {}

sub DEMOLISH {
    my $self = shift;
    $self->finalize unless $self->finalized;
}

__PACKAGE__->meta->make_immutable;

