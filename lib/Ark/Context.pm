package Ark::Context;
use Mouse;
use Mouse::Util::TypeConstraints;

use Ark::Request;
use HTTP::Engine::Response;
use Scalar::Util ();

our $DETACH = 'ARK_DETACH';

subtype 'Ark::Request'
    => as 'Object'
    => where { $_->isa('Ark::Request') };

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
                 'component', 'view', 'model', 'path_to', ],
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

has debug_report => (
    is      => 'rw',
    isa     => 'Text::SimpleTable',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->ensure_class_loaded('Text::SimpleTable');
        Text::SimpleTable->new([62, 'Action'], [9, 'Time']);
    },
);

has debug_report_stack => (
    is      => 'rw',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub { [] },
);

{   # alias
    no warnings 'once';
    *req = \&request;
    *res = \&response;
}

sub process {
    my $self = shift;

    my $start;
    if ($self->debug) {
        $self->ensure_class_loaded('Time::HiRes');
        $start = [Time::HiRes::gettimeofday()];
    }

    $self->prepare;
    $self->dispatch;
    $self->finalize;

    if ($self->debug) {
        my $elapsed = sprintf '%f', Time::HiRes::tv_interval($start);
        my $av = $elapsed == 0 ? '??' : sprintf '%.3f', 1 / $elapsed;
        $self->log( debug => "Request took ${elapsed}s ($av/s)\n%s",
                    $self->debug_report->draw );
    }
}

sub prepare {
    my $self = shift;
    my $req  = $self->request;

    my @path = split /\//, $req->path;
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

    $self->log( debug => q/"%s" request for "%s" from "%s"/,
                $req->method, $req->path, $req->address );
    $self->log( debug => q/Arguments are "%s"/, join('/', @{ $req->arguments }) );
}

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

    if ($self->debug) {
        $self->ensure_class_loaded('Time::HiRes');
        $self->stack->[-1]->{start} = [Time::HiRes::gettimeofday()];
    }

    eval {
        $self->state( $obj->$method($self, @args) );
    };

    my $last = pop @{ $self->stack };

    if ($self->debug) {
        my $elapsed = $last->{elapsed} = Time::HiRes::tv_interval( $last->{start} );

        my $name;
        if ($last->{obj}->isa('Ark::Controller')) {
            $name = $last->{obj}->namespace
                ? '/' . $last->{obj}->namespace . '/' . $last->{method}
                : $last->{obj}->namespace . '/' . $last->{method};
        }
        else {
            $name = $last->{as_string};
        }

        if ($self->depth) {
            $name = ' ' x $self->depth . '-> ' . $name;
            push @{ $self->debug_report_stack }, [ $name, sprintf("%fs", $elapsed) ];
        }
        else {
            $self->debug_report->row( $name, sprintf("%fs", $elapsed));
            while (my $report = pop @{ $self->debug_report_stack }) {
                $self->debug_report->row(@$report);
            }
        }
    }

    if (my $error = $@) {
        if ($error =~ /^${DETACH} at /) {
            die $DETACH if ($self->depth > 1);
        }
        else {
            push @{ $self->error }, $error;
            $self->state(0);
        }
    }

    $self->state;
}

sub finalize { }

1;

