package Ark::Context;
use Mouse;
use Mouse::Util::TypeConstraints;

use Ark::Request;
use HTTP::Engine::Response;

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
    handles  => ['log'],
);

has stash => (
    is      => 'rw',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { {} },
);

has setup_finished => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

after 'setup' => sub { shift->setup_finished(1) };

{   # alias
    no warnings 'once';
    *req = \&request;
    *res = \&response;
}

sub setup { }

sub process {
    my $self = shift;

    $self->prepare;
    $self->dispatch;
    $self->finalize;
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

    $self->log( debug => 'Path is "%s"', $req->match );
    $self->log( debug => 'Arguments are "%s"', join('/', @{ $req->args }) );
}

sub dispatch {
    my $self = shift;

    my $action = $self->request->action;
    if ($action) {
        $action->dispatch($self);
    }
    else {
        $self->log( error => 'no action found' );
    }
}

sub finalize { }

1;

