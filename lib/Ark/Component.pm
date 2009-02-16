package Ark::Component;
use Mouse;

has context => (
    is       => 'rw',
    isa      => 'Ark::Core',
    weak_ref => 1,
);

has component_name => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self  = shift;
        (my $name = ref $self) =~ s/^.*?::(Controller|View|Model)::/$1::/;
        $name;
    },
);

no Mouse;

sub apply_config {
    my ($self, $config) = @_;

    for my $k (keys %{ $config || {} }) {
        $self->{ $k } = $config->{$k};
    }
}

1;

