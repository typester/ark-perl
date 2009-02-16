package Ark::Action;
use Mouse;

has [qw/class namespace reverse name/] => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has attributes => (
    is       => 'rw',
    isa      => 'HashRef',
    required => 1,
);

has controller => (
    is       => 'rw',
    isa      => 'Ark::Controller',
    required => 1,
);

has code => (
    is       => 'rw',
    isa      => 'CodeRef',
    required => 1,
);

no Mouse;

sub match {
    my ($self, $req) = @_;

    return 1 unless exists $self->attributes->{Args};

    my $args = $self->attributes->{Args}[0];
    return 1 unless defined($args) && length($args);
    return scalar( @{ $req->args } ) == $args;
}

sub dispatch {
    my $self = shift;

    my $method = $self->code;
    $self->controller->$method(@_);
}

1;

