package TestApp::Controller::Two;
use Ark 'Controller';

use Test::More;

sub index :Path :Args(0) {
    my ($self, $c) = @_;

    $c->res->{body} .= '/two/index';
}

__PACKAGE__->meta->make_immutable;

