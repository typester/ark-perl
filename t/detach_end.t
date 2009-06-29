use Test::Base;

{
    package TestApp;
    use Ark;

    package TestApp::Controller::Root;
    use Ark 'Controller';
    has '+namespace' => default => '';

    sub end :Private {
        my ($self, $c) = @_;
        $c->res->body( $c->res->body . '/end' );
    }

    package TestApp::Controller::C1;
    use Ark 'Controller';

    sub index :Path :Args(0) {
        my ($self, $c) = @_;
        $c->res->body('c1');
    }

    sub detach :Local :Args(0) {
        my ($self, $c) = @_;
        $c->detach('next');
    }

    sub next :Local :Args(0) {
        my ($self, $c) = @_;
        $c->res->body('next');
    }
}

use Ark::Test 'TestApp',
    components => [qw/Controller::Root Controller::C1/];

plan 'no_plan';

{
    my $res = request( GET => '/c1' );
    ok($res->is_success, 'response ok');
    is($res->content, 'c1/end', 'normal end ok');
}

{
    my $res = request( GET => '/c1/detach' );
    ok($res->is_success, 'response ok');
    is($res->content, 'next/end', 'end action after detach' );
}
