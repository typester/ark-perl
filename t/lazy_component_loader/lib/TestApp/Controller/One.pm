package TestApp::Controller::One;
use Ark 'Controller';

use Test::More;

sub index :Path :Args(0) {
    my ($self, $c) = @_;

    ok(!$INC{'TestApp/View/Test.pm'}, 'view is not loaded ok');

    $c->forward( $c->view('Test') );

    ok($INC{'TestApp/View/Test.pm'}, 'view is loaded ok');
}

1;

