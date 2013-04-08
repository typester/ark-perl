package T3::Models;
use Ark::Models -base;

autoloader qr/^Schema::/ => sub {
    my ($self, $name) = @_;

    $self->ensure_class_loaded($name);
    "$name"->new;
};


1;
