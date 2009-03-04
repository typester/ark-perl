package TestApp::Controller::Root;
use Ark 'Controller';

has '+namespace' => default => '';

sub default :Path {
    my ($self, $c) = @_;
}

1;

