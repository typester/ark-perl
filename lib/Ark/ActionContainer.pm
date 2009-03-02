package Ark::ActionContainer;
use Mouse;

has namespace => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has actions => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
);

no Mouse;

1;

