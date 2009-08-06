use Test::Base;

{
    package TestApp;
    use Ark;

    package TestApp::Controller::Root;
    use Ark 'Controller';

    has '+namespace' => default => '';

    sub default :Path :Args {
        my ($self, $c) = @_;
        $c->res->status(404);
        $c->res->content('404');
    }

    sub index :Path {
        my ($self, $c) = @_;
        $c->res->content('index');
    }

    sub local :Local {
        my ($self, $c) = @_;
        $c->res->content('local');
    }

    sub local2 :Local :Args(2) {
        my ($self, $c, @args) = @_;
        $c->res->content(join ',', @args);
    }

    sub local3 :Local {
        my ($self, $c) = @_;
        $c->res->content('local3');
    }

    sub local4 :Local :Args(1) {
        my ($self, $c, $a1) = @_;
        $c->res->content('local4:'. $a1);
    }

    package TestApp::Controller::Sub;
    use Ark 'Controller';

    sub index :Path {
        my ($self, $c) = @_;
        $c->res->content('sub/index');
    }

    sub global :Global {
        my ($self, $c) = @_;
        $c->res->content('global');
    }

    package TestApp::Controller::Sub::Deep;
    use Ark 'Controller';

    sub index :Path {
        my ($self, $c) = @_;
        $c->res->content('sub/deep/index');
    }
}

plan 'no_plan';

use Ark::Test 'TestApp',
    components => [
        qw/
            Controller::Root
            Controller::Sub
            Controller::Sub::Deep
            /
    ];

{
    my $res = request( GET => '/');
    ok($res, 'response ok');
    isa_ok($res, 'HTTP::Response');
    is($res->content, 'index', 'index content ok');
}

{
    my $res = request( GET => '/404');
    ok($res, 'response ok');
    isa_ok($res, 'HTTP::Response');
    is($res->code, 404, '404 status code ok');
    is($res->content, '404', '404 content ok');
}

{
    my $res = request( GET => '/local' );
    ok($res, 'response ok');
    isa_ok($res, 'HTTP::Response');
    is($res->code, 200, '200 status code ok');
    is($res->content, 'local', 'local content ok');
}

{
    my $res = request( GET => '/local2/a1/a2' );
    is($res->content, 'a1,a2', 'local2 with args content ok');
}

{
    my $res = request( GET => '/local3' );
    is($res->content, 'local3', 'local3 with args content ok');

    $res = request( GET => '/local3/a1' );
    is($res->code, 404, '404 status ok');
    is($res->content, '404', 'local3 with args == 404 ok');
}

{
    my $res = request( GET => '/local4/a1' );
    is($res->content, 'local4:a1', 'local4 with args content ok');

    $res = request( GET => '/local4' );
    is($res->code, '404', 'local4 with no args is 404 ok');

    $res = request( GET => '/local4/a1/a2/' );
    is($res->code, '404', 'local4 with too many args is 404 ok');
}

{
    my $res = request( GET => '/sub');
    is($res->code, 200, '200 status ok');
    is($res->content, 'sub/index', 'sub/index ok');
}

{
    my $res = request( GET => '/global' );
    is($res->code, 200, '200 status ok');
    is($res->content, 'global', 'global content ok');
}

{
    my $res = request( GET => '/sub/deep' );
    is($res->code, 200, '200 status ok');
    is($res->content, 'sub/deep/index', 'sub/deep/index ok');
}
