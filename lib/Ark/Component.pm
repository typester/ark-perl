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

no Mouse;

sub config {
    my $class  = shift;
    my $config = @_ > 1 ? {@_} : $_[0];

    $class->__component_config({}) unless $class->__component_config;

    if ($config) {
        for my $key (%{ $config || {} }) {
            $class->__component_config->{ $key } = $config->{$key};
        }
    }

    $class->__component_config;
}

sub component_name {
    my $class = shift;
    $class = ref $class if ref $class;

    (my $name = $class) =~ s/^.*?::(Controller|View|Model)::/$1::/;
    $name;
}

1;
