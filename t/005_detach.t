use strict;
use warnings;
use Test::More;

{
    package TestApp;
    use Ark;

    package TestApp::Controller::One;
    use Ark 'Controller';

    sub one :Local {
        my ($self, $c) = @_;
        $c->res->{body} .= 'one_';
        $c->forward('two');
    }

    sub two :Local {
        my ($self, $c) = @_;
        $c->res->{body} .= 'two_';
        $c->detach('three');
        $c->res->{body} .= 'wrong_two_';
    }

    sub three :Local {
        my ($self, $c) = @_;
        $c->res->{body} .= 'three';
    }

    package TestApp::Controller::Two;
    use Ark 'Controller';

    sub one :Local {
        my ($self, $c) = @_;
        $c->res->{body} .= 'one_';
        $c->detach;
        $c->forward('two');
    }

    sub two :Local {
        my ($self, $c) = @_;
        $c->res->{body} .= 'two_';
    }
}

use Ark::Test 'TestApp',
    components => [qw/Controller::One
                      Controller::Two
                     /];


{
    my $res = request( GET => '/one/one' );
    ok($res->is_success, 'response ok');
    is($res->content, 'one_two_three', 'detach response ok');
}

{
    my $res = request( GET => '/two/one' );
    ok($res->is_success, 'response ok');
    is($res->content, 'one_', 'detach response ok');
}

done_testing;
