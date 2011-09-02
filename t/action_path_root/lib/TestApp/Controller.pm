package TestApp::Controller;
use Ark 'Controller';

sub index :Path {
    my ($self, $c) = @_;
    $c->res->body('root');
}

__PACKAGE__->meta->make_immutable;
