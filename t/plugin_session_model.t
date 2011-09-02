use Test::Base;

eval "use Cache::MemoryCache";
plan skip_all => 'Cache::MemoryCache required to run this test' if $@;


{
    package T1;
    use Ark;

    use_plugins qw/
        Session
        Session::State::Cookie
        Session::Store::Model
        /;

    conf 'Plugin::Session' => {
        expire => 3,
    };

    conf 'Plugin::Session::Store::Model' => {
        model => 'Session',
    };

    conf 'Model::Session' => {
        class => 'Cache::MemoryCache',
        args  => {
            namespace          => 'session',
            default_expires_in => 24*60 * 1,
        },
    };

    package T1::Model::Session;
    use Ark 'Model::Adaptor';

    package T1::Controller::Root;
    use Ark 'Controller';

    has '+namespace' => default => '';

    sub test_set :Local {
        my ($self, $c) = @_;
        $c->session->set('test', 'testdata');
    }

    sub test_get :Local {
        my ($self, $c) = @_;
        $c->res->body( $c->session->get('test') );
    }

    sub incr :Local {
        my ($self, $c) = @_;

        my $count = $c->session->get('count') || 0;
        $c->session->set( count => ++$count );

        $c->res->body( $count );
    }

    sub prefix: Local {
        my ($self, $c) = @_;
        $c->res->body( $c->session->store_model_key_prefix );
    }
}

plan 'no_plan';

use Ark::Test 'T1',
    components => [qw/Controller::Root Model::Session/],
    reuse_connection => 1;

{
    my $res = request(GET => '/test_set');
    like( $res->header('Set-Cookie'), qr/t1_session=/, 'session id ok');

    is(get('/test_get'), 'testdata', 'session get ok');
}

{
    is(get('/incr'), 1, 'increment first ok');
    is(get('/incr'), 2, 'increment second ok');
    reset_app;

    is(get('/incr'), 1, 're-increment first ok'); # XXX: this is test for Ark::Test: should be sepalate test.
    is(get('/incr'), 2, 're-increment second ok');
}

{
    is(get('/prefix'), 'session:', 'key_prefix is default');
}

{
    package T1;
    use Ark;
    conf 'Plugin::Session::Store::Model' => {
        key_prefix => 'key_prefix_of_session:',
        model      => 'Session',
    };
}

{
    is(get('/prefix'), 'key_prefix_of_session:', 'specified prefix used');
}

{
    request(GET => '/test_set');
    is(get('/test_get'), 'testdata', 'session get ok');
    sleep 1;
    is(get('/test_get'), 'testdata', 'session get after 1sec ok');
    sleep 3;
    is(get('/test_get'), '', 'session expired ok');
}
