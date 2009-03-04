package TestApp::Controller::One;
use Ark 'Controller';

use Test::More;

sub index :Path :Args(0) {
    my ($self, $c) = @_;

    ok(!$INC{'TestApp/Controller/Two.pm'}, q[Controller::Two doesn't load yet]);

    $c->res->{body} .= '/one/index';
}

1;

