package Ark::ActionContainer;
use Any::Moose;

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

no Any::Moose;

__PACKAGE__->meta->make_immutable;

