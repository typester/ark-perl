use Test::Base;

{
    package TestApp;
    use Ark;

    use_plugins qw/
        Session
        Session::State::Cookie
        Session::Store::Memory
        /;

    conf 'Plugin::Session::State::Cookie' => {
        cookie_expires => '+3d',
    };

    package TestApp::Controller::Root;
    use Ark 'Controller';

    has '+namespace' => default => '';

    sub test_set :Local {
        my ($self, $c) = @_;
        $c->session->set('test', 'dummy');
    }

    sub test_flash_set :Local {
        my ($self, $c) = @_;
        $c->session->set('test', 'dummy_flash');
    }

    sub test_get :Local {
        my ($self, $c) = @_;
        $c->res->body( $c->session->get('test') );
    }

    sub test_flash_get :Local {
        my ($self, $c) = @_;
        $c->res->body( $c->session->remove('test') || "" );
    }

    sub incr :Local {
        my ($self, $c) = @_;

        my $count = $c->session->get('count') || 0;
        $c->session->set( count => ++$count );

        $c->res->body( $count );
    }

    sub regen :Local {
        my ($self, $c) = @_;
        $c->session->regenerate;
        $c->res->body('regenerated');
    }

    sub regen_and_incr :Local {
        my ($self, $c) = @_;
        $c->forward('regen');
        $c->forward('incr');
    }
}

plan 'no_plan';

use Ark::Test 'TestApp',
    components       => [qw/Controller::Root/],
    reuse_connection => 1;

{
    my $res = request(GET => '/test_set');
    like( $res->header('Set-Cookie'), qr/testapp_session=/, 'session id ok');
    like( $res->header('Set-Cookie'), qr/expires=./, 'session expire ok');

    is(get('/test_get'), 'dummy', 'session get ok');
}

{
    my $res = request(GET => '/test_flash_set');
    like( $res->header('Set-Cookie'), qr/testapp_session=/, 'session id ok');

    is(get('/test_flash_get'), 'dummy_flash', 'flash get ok');
    is(get('/test_flash_get'), '', 'flash cleaered ok');
}

{
    is(get('/incr'), 1, 'increment first ok');
    is(get('/incr'), 2, 'increment second ok');
    reset_app;

    is(get('/incr'), 1, 're-increment first ok'); # XXX: this is test for Ark::Test: should be sepalate test.
    is(get('/incr'), 2, 're-increment second ok');
}

{
    # sid regeneration
    reset_app;

    my $res;
    $res = request(GET => '/incr');
    is $res->content, 1, 'request ok';

    my ($sid) = $res->header('Set-Cookie') =~ /testapp_session=(\w+)/;
    ok $sid, 'sid ok';

    $res = request(GET => '/regen');
    is $res->content, 'regenerated', 'sid regenerated';
    my ($new_sid) = $res->header('Set-Cookie') =~ /testapp_session=(\w+)/;

    is get('/incr'), 2, 'session continued ok';
    isnt $sid, $new_sid, 'but session_id updated ok';

    is get('/regen_and_incr'), 3, 'modified session data and regenerated sid on the same request ok';

    # old sid is now removed
    my $request = HTTP::Request->new(GET => '/incr');
    $request->header( Cookie => "testapp_session=$sid" );
    is request($request)->content, 1, 'old session already expired';
}
