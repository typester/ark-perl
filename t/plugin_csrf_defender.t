use Test::Base;

{
    package TestApp;
    use Ark;

    use_plugins qw/
        Session
        Session::State::Cookie
        Session::Store::Memory
        CSRFDefender
        /;

    conf 'Plugin::Session::State::Cookie' => {
        cookie_expires => '+3d',
    };

    package TestApp::Controller::Root;
    use Ark 'Controller';

    has '+namespace' => default => '';

    sub test_set :Local {
        my ($self, $c) = @_;
        $c->session->set('csrf_token', 'dummy');
    }

    sub test_get :Local {
        my ($self, $c) = @_;
        $c->session->remove('csrf_token');
    }
}

plan 'no_plan';

use Ark::Test 'TestApp',
    components       => [qw/Controller::Root/],
    reuse_connection => 1;

{
    my ($res, $c) = ctx_request(GET => '/test_set');
    is length $c->csrf_token, 5;
}

{
    my ($res, $c) = ctx_request(GET => '/test_get');
    is length $c->csrf_token, 16;
}

{
    for my $method (qw(POST PUT DELETE)) {
        my ($res, $c) = ctx_request($method => '/test_set?csrf_token=dummy');
        is $c->validate_csrf_token, 1;
    }
}

{
    for my $method (qw(POST PUT DELETE)) {
        my ($res, $c) = ctx_request($method => '/test_set?csrf_token=fuga');
        is $c->validate_csrf_token, 0;
    }
}

{
    my ($res, $c) = ctx_request(GET => '/test_get');
    like $c->html_filter_for_csrf('<form></form>'), qr/name="csrf_token"/;
}
