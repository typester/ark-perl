package TestApp::Controller::Root;
use Ark 'Controller';

has '+namespace' => default => '';

sub maketext :Local :Args(1) {
    my ($self, $c, $key) = @_;
    $c->res->body( $c->localize($key) );
}

sub current_language :Local {
    my ($self, $c) = @_;
    $c->res->body( $c->language );
}

1;
