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

        $c->res->content($c->_has_csrf_token ? 'OK' : 'NG');
    }

    sub test_get :Local {
        my ($self, $c) = @_;

        $c->res->body('<form></form>');
    }
}

use Ark::Test 'TestApp',
    components       => [qw/Controller::Root/],
    reuse_connection => 1;

subtest 'token_length' => sub {
    my $c = ctx_get '/test_get';
    is length $c->csrf_token, 36;
};

subtest 'token_fix' => sub {
    my $c = ctx_get '/test_set';
    is length $c->csrf_token, 36;
    is $c->res->body, 'OK';

    $c = ctx_get '/test_get';
    is length $c->csrf_token, 5;
};

subtest 'validate_ok' => sub {
    for my $method (qw(GET POST PUT DELETE)) {
        my ($res, $c) = ctx_request($method => '/test_get?csrf_token=dummy');
        is $c->validate_csrf_token, 1;
    }
};

subtest 'validate NG' => sub {
    for my $method (qw(POST PUT DELETE)) {
        my ($res, $c) = ctx_request($method => '/test_get?csrf_token=fuga');
        ok !$c->validate_csrf_token;
        is $c->res->content, $c->csrf_defender_error_output;
        is $c->res->code, 403;
    }

    my $c = ctx_get '/test_get?csrf_token=fuga';
    is $c->res->code, 200;
};

subtest 'rewrite body' => sub {
    my $c = ctx_get '/test_get';
    like $c->res->body, qr/name="csrf_token"/;
};

done_testing;
