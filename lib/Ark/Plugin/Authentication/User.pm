package Ark::Plugin::Authentication::User;
use Mouse;

has obj => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $builder = $self->obj_builder;
        return $self->obj_builder->() if $builder;
    },
);

has obj_builder => (
    is  => 'rw',
    isa => 'CodeRef',
);

has hash => (
    is      => 'rw',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { {} },
);

has store => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

sub authenticated {
    my $self = shift;
    !!$self->obj;
}

sub for_session {
    my $self = shift;

    return {
        hash  => $self->hash,
        store => $self->store,
    };
}

1;
