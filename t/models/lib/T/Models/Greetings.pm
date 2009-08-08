package T::Models::Greetings;
use Mouse;

sub hello {
    my ($self, $name) = @_;
    "Hello, $name";
}

1;

