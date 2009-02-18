package Ark::Request;
use Mouse;

use HTTP::Engine::Response;

extends 'HTTP::Engine::Request';

has stash => (
    is      => 'rw',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { {} },
);

has action => (
    is  => 'rw',
    isa => 'Ark::Action',
);

has match => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub { '' },
);

has args => (
    is      => 'rw',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub { [] },
);

has captures => (
    is      => 'rw',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub { [] },
);

has response => (
    is      => 'rw',
    isa     => 'HTTP::Engine::Response',
    lazy    => 1,
    default => sub { HTTP::Engine::Response->new },
);

has context => (
    is       => 'rw',
    isa      => 'Ark::Core',
    weak_ref => 1,
    required => 1,
    handles  => ['log'],
);

no Mouse;

{
    no warnings 'once';
    *res = \&response;
}

sub prepare_action {
    my $self = shift;

    my @path = split /\//, $self->path;
    unshift @path, '' unless @path;

 DESCEND: while (@path) {
        my $path = join '/', @path;
        $path =~ s!^/!!;

        for my $type (@{ $self->context->dispatch_types }) {
            last DESCEND if $type->match( $self, $path );
        }

        my $arg = pop @path;
        $arg =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
        unshift @{ $self->args }, $arg;
    }

    s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg
        for grep {defined} @{ $self->captures || [] };

    $self->log( debug => 'Path is "%s"', $self->match );
    $self->log( debug => 'Arguments are "%s"', join('/', @{ $self->args }) );

    $self->action;
}

1;
