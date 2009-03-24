package Ark::Plugin::Authentication::Store::DBIx::Class::User;
use Mouse;

extends 'Ark::Plugin::Authentication::User';

has obj => (
    is      => 'rw',
    isa     => 'DBIx::Class::Row',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->obj_builder->();
    },
);

has hash => (
    is      => 'rw',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { {} },
);

has obj_builder => (
    is  => 'rw',
    isa => 'CodeRef',
);

1;

