use Test::More;

{
    package T;
    use Ark;

    package T::Controller::Root;
    use Ark 'Controller';
    has '+namespace' => default => '';

    sub default :Private {
        my ($self, $c) = @_;
        $c->res->body('404');
    }

    package T::Controller::Entry;
    use Ark 'Controller';

    sub entry :Chained('/') :PathPart('entry') :CaptureArgs(1) {
        my ($self, $c, $entry_id) = @_;
        $c->stash->{entry} = $entry_id;
        $c->res->body("entry$entry_id");
    }

    sub more :Chained('entry') :PathPart('more') :Args(0) {
        my ($self, $c) = @_;
        $c->forward('check');
        $c->res->body( $c->res->body . "aftercheck" );
    }

    sub check :Private {
        my ($self, $c) = @_;
        $c->detach('/default') if $c->stash->{entry} == 0;
    }
}

use Ark::Test 'T',
    components => [qw/Controller::Root Controller::Entry/];

{
    my $res = request( GET => '/entry/1/more' );
    ok($res->is_success, 'response ok');
    is($res->content, 'entry1aftercheck', 'chained without detach response ok');
}

{
    my $res = request( GET => '/entry/0/more' );
    ok($res->is_success, 'response ok');
    is($res->content, '404', 'chained with detach response ok');
}

done_testing;

__END__

web03% prove -vlr t/detach_action_chain2.t
t/detach_action_chain2.t ..
ok 1 - response ok
ok 2 - chained without detach response ok
ok 3 - response ok
not ok 4 - chained with detach response ok
#   Failed test 'chained with detach response ok'
#   at t/detach_action_chain2.t line 49.
#          got: '404aftercheck'
#     expected: '404'
1..4
# Looks like you failed 1 test of 4.
Dubious, test returned 1 (wstat 256, 0x100)
Failed 1/4 subtests

Test Summary Report
-------------------
t/detach_action_chain2.t (Wstat: 256 Tests: 4 Failed: 1)
  Failed test:  4
  Non-zero exit status: 1
Files=1, Tests=4,  0 wallclock secs ( 0.03 usr  0.00 sys +  0.27 cusr  0.02 csys =  0.32 CPU)
 Result: Failed
