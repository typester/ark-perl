use strict;
use warnings;
use Test::More;

{
    package T;
    use Ark;

    package T::Controller::Root;
    use Ark 'Controller';

    has '+namespace' => default => '';

    sub normal :Local :Args(0) {
        my ($self, $c) = @_;

        $c->redirect_and_detach( $c->uri_for('/redirected') );
        $c->res->body('no execute here');
    }

    sub with_status :Local :Args(0) {
        my ($self, $c) = @_;

        $c->redirect_and_detach( $c->uri_for('/redirected_301'), 301 );
        $c->res->body('no execute here');
    }
}


use Ark::Test 'T', components => [qw/Controller::Root/];

{
    ok( my $res = request(GET => '/normal') );
    is($res->code, 302, 'redirect status ok');
    is($res->content, '', 'content does not set');
    is($res->header('Location'), 'http://localhost/redirected', 'redirect header ok');
}

{
    ok( my $res = request(GET => '/with_status') );
    is($res->code, 301, 'redirect status');
    is($res->content, '', 'content does not set');
    is($res->header('Location'), 'http://localhost/redirected_301', 'redirect header ok');
}

done_testing;
