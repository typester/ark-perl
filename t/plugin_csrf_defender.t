use strict;
use warnings;
use Test::More;

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

        $c->res->body('<form></form>');
    }
}


use Ark::Test 'TestApp',
    components       => [qw/Controller::Root/],
    reuse_connection => 1;

{
    my ($res, $c) = ctx_request(GET => '/test_set');
    is length $c->csrf_token, 5;
}

{
    my ($res, $c) = ctx_request(GET => '/test_get');
    is length $c->csrf_token, 36;
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
        ok !$c->validate_csrf_token;
    }
}

{
    my ($res, $c) = ctx_request(GET => '/test_get');
    like $c->res->body, qr/name="csrf_token"/;
}
done_testing;
