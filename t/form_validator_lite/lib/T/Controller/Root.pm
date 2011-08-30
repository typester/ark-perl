package T::Controller::Root;
use Ark "Controller";

has '+namespace' => default => '';

sub login :Local :Args(0) {
    my ($self, $c) = @_;
}

1;
