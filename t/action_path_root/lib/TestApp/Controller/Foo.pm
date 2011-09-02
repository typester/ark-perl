package TestApp::Controller::Foo;
use Ark 'Controller';

sub index :Path {
    my ($self, $c) = @_;
    $c->res->body('foo');
}

__PACKAGE__->meta->make_immutable;
