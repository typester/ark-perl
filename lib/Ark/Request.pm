package Ark::Request;
use Mouse;

extends 'HTTP::Engine::Request';

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

has arguments => (
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

{
    no warnings 'once';
    *args = \&arguments;
}

no Mouse;

1;

