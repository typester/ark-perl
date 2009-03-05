package Ark::Component;
use Mouse;

extends 'Mouse::Object', 'Class::Data::Inheritable';

__PACKAGE__->mk_classdata(qw/__component_config/);

has app => (
    is       => 'rw',
    isa      => 'Ark::Core',
    weak_ref => 1,
    handles  => ['log', 'context', 'ensure_class_loaded', 'path_to'],
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

sub config {
    my $class  = shift;
    my $config = @_ > 1 ? {@_} : $_[0];

    if ($config) {
        $class->__component_config($config);
    }

    $class->__component_config || {};
}

sub apply_config {
    my ($self, $config) = @_;

    for my $k (keys %{ $config || {} }) {
        $self->{ $k } = $config->{$k};
    }

    for my $k (keys %{ $self->config || {} }) {
        $self->{ $k } = $self->config->{$k};
    }
}

1;

