package TestApp::View::Test;
use Ark 'View';

use Test::More;

sub process {
    my ($self, $c) = @_;
    $c->res->body('view loaded');
}

1;

