package TestApp::SubApp::Controller;
use Ark 'Controller';

sub hello :Local {
    my ($self, $c) = @_;
    $c->res->body( $c->localize('Hello') );
}

1;
