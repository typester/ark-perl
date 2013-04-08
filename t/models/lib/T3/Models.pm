package T3::Models;
use Ark::Models -base;

autoloader qr/^Schema::/ => sub {
    my ($self, $name) = @_;

    my $pkg = "T3::$name";

    $self->ensure_class_loaded($pkg);
    $self->register( "$name" => sub { $pkg->new } );
};


1;
