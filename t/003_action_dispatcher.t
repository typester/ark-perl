use strict;
use warnings;
use Test::More;

{
    package TestApp;
    use Ark;

    package TestApp::Controller::Order;
    use Ark 'Controller';

    sub begin :Private {
        my ($self, $c) = @_;
        $c->res->body( ($c->res->body || '') . 'begin1' );
    }

    sub auto :Private {
        my ($self, $c) = @_;
        $c->res->body( ($c->res->body || '') . 'auto1' );
    }

    sub index :Path {
        my ($self, $c) = @_;
        $c->res->body( ($c->res->body || '') . 'action1' );
    }

    sub end :Private {
        my ($self, $c) = @_;
        $c->res->body( ($c->res->body || '') . 'end1' );
    }

    package TestApp::Controller::Order::Cascade;
    use Ark 'Controller';

    sub begin :Private {
        my ($self, $c) = @_;
        $c->res->body( ($c->res->body || '') . 'begin2' );
    }

    sub auto :Private {
        my ($self, $c) = @_;
        $c->res->body( ($c->res->body || '') . 'auto2' );
    }

    sub index :Path {
        my ($self, $c) = @_;
        $c->res->body( ($c->res->body || '') . 'action2' );
    }

    sub end :Private {
        my ($self, $c) = @_;
        $c->res->body( ($c->res->body || '') . 'end2' );
    }

    package TestApp::Controller::StopAuto;
    use Ark 'Controller';

    sub begin :Private {
        my ($self, $c) = @_;
        $c->res->body( ($c->res->body || '') . 'begin1' );
    }

    sub auto :Private {
        my ($self, $c) = @_;
        $c->res->body( ($c->res->body || '') . 'auto1' );
        return;
    }

    sub index :Path {
        my ($self, $c) = @_;
        $c->res->body( ($c->res->body || '') . 'action1' );
    }

    sub end :Private {
        my ($self, $c) = @_;
        $c->res->body( ($c->res->body || '') . 'end1' );
    }
}

use Ark::Test 'TestApp';


{
    my $res = request( GET => '/order' );
    ok($res->is_success, 'request success');
    is($res->content, 'begin1auto1action1end1', 'action order ok');
}

{
    my $res = request( GET => '/order/cascade' );
    ok($res->is_success, 'request success');
    is($res->content, 'begin2auto1auto2action2end2', 'cascade action order ok');
}

{
    my $res = request( GET => '/stopauto' );
    ok($res->is_success, 'request success');
    is($res->content, 'begin1auto1end1', 'stop auto ok');

}
done_testing;
