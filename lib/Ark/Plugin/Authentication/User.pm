package Ark::Plugin::Authentication::User;
use Mouse;

has obj => (
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

sub hash {
    my $self = shift;
    $self->obj;
}

1;
