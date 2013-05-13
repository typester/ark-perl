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

    config 'Plugin::Session::State::Cookie' => {
        cookie_expires => '+3d',
    };

    config 'Plugin::CSRFDefender' => {
        error_action => '/csrf_error',
    };

    package TestApp::Controller::Root;
    use Ark 'Controller';

    has '+namespace' => default => '';

    sub csrf_error :Local {
        my ($self, $c) = @_;

        $c->res->body('wryyy');
    }

    sub test_set :Local {
        my ($self, $c) = @_;
        $c->session->set('csrf_token', 'dummy');
    }

    sub test_get :Local {
        my ($self, $c) = @_;

        $c->res->body('OK');
    }
}

use Ark::Test 'TestApp',
    components       => [qw/Controller::Root/],
    reuse_connection => 1;

ctx_get '/test_set';
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
        is $c->res->code, 403;
        is $c->res->body, 'wryyy';
    }

    my $c = ctx_get '/test_get';
    is $c->res->code, 200;
    is $c->res->content, 'OK';
};

done_testing;
