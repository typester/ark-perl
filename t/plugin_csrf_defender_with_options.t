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
        error_code    => 400,
        error_output  => 'ERROR!',
        validate_only => 1,
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

    sub raise_error :Local {
        my ($self, $c) = @_;

        if (!$c->validate_csrf_token) {
            $c->forward_csrf_error;
            $c->detach;
        }
        $c->res->body('OK');
    }
}

use Ark::Test 'TestApp',
    components       => [qw/Controller::Root/],
    reuse_connection => 1;

# set dummy token
ctx_get '/test_set';

subtest 'validate_ok' => sub {
    for my $method (qw(GET POST PUT DELETE)) {
        my ($res, $c) = ctx_request($method => '/test_set?csrf_token=dummy');
        is $c->validate_csrf_token, 1;
    }
};

subtest 'validate NG' => sub {
    for my $method (qw(POST PUT DELETE)) {
        my ($res, $c) = ctx_request($method => '/test_set?csrf_token=fuga');
        ok !$c->validate_csrf_token;
        is $c->res->code, 200;
    }

    for my $method (qw(POST PUT DELETE)) {
        my ($res, $c) = ctx_request($method => '/raise_error?csrf_token=fuga');
        ok !$c->validate_csrf_token;
        is $c->res->content, 'ERROR!';
        is $c->res->code, 400;
    }

    my $c = ctx_get '/raise_error';
    is $c->res->code, 200;
    is $c->res->content, 'OK';
};

done_testing;
