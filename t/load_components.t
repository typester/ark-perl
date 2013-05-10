use strict;
use warnings;
use Test::More;

{
    package TestApp;
    use Ark;

    package TestApp::Controller::Root;
    use Ark 'Controller';

    has '+namespace' => default => '';

    sub view :Local {
        my ($self, $c) = @_;
        $c->res->body( ref $c->view('TT') );
    }

    sub model :Local {
        my ($self, $c) = @_;
        $c->res->body( ref $c->model('DB') );
    }

    package TestApp::View::TT;
    use Ark 'View';

    package TestApp::Model::DB;
    use Ark 'Model';

}

use Ark::Test 'TestApp',
    components => [qw/Controller::Root
                      View::TT
                      Model::DB
                     /];


is(get('/view'), 'TestApp::View::TT', 'view() ok');
is(get('/model'), 'TestApp::Model::DB', 'model() ok');
done_testing;
