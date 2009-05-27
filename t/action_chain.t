use Test::Base;

{
    package T1;
    use Ark;

    package T1::Controller::Root;
    use Ark 'Controller';

    has '+namespace' => default => '';

    sub one :Chained('/') :PathPart :CaptureArgs(1) {
        my ($self, $c, $one) = @_;
        $c->stash->{one} = $one;
    }

    sub end :Chained('one') :PathPart :Args(1) {
        my ($self, $c, $end) = @_;
        $c->res->body( $c->stash->{one} . $end );
    }
}

{
    package T2;
    use Ark;

    package T2::Controller::Root;
    use Ark 'Controller';

    has '+namespace' => default => '';

    sub user :Chained('/') :PathPart('') :CaptureArgs(1) {
        my ($self, $c, $user) = @_;
        $c->stash->{user} = $user;
    }

    sub profile :Chained('user') :PathPart :Args(0) {
        my ($self, $c) = @_;
        $c->res->body( $c->stash->{user} . '\'s profile');
    }

    sub status :Chained('user') :PathPart :Args(1) {
        my ($self, $c, $status_id) = @_;
        $c->res->body( $c->stash->{user} . '\'s status: ' . $status_id);
    }

    sub profile_edit :Chained('user') :PathPart('profile/edit') :Args(0) {
        my ($self, $c) = @_;
        $c->res->body($c->stash->{user} . q['s profile edit]);
    }

    sub status_chain :Chained('user') :PathPart('status') :CaptureArgs(1) {
        my ($self, $c, $status) = @_;
        $c->stash->{status} = $status;
    }

    sub status_remove :Chained('status_chain') :PathPart('remove') :Args(0) {
        my ($self, $c) = @_;
        $c->res->body(
            $c->stash->{user} . q['s status: "] . $c->stash->{status} . q[" will remove]
        );
    }

    package T2::Controller::Status;
    use Ark 'Controller';

    sub update :Chained('/status_chain') :PathPart :Args(0) {
        my ($self, $c) = @_;
        $c->res->body(
            $c->stash->{user} . q['s status: "] . $c->stash->{status} . q[" will update]
        );
    }
}

plan 'no_plan';

require Ark::Test;

import Ark::Test 'T1',
    components => [qw/Controller::Root/];

is(get('/one/one/end/end'), 'oneend', 'simple request ok');


import Ark::Test 'T2', components => [qw/Controller::Root Controller::Status/];

my $tests = sub {
    is( get('/typester/profile'),
        q[typester's profile],
        '/{user}/profile ok'
    );
    is( get('/typester/status/4423'),
        q[typester's status: 4423],
        '/{user}/status/{status_id} ok'
    );

    is( get('/typester/profile/edit'),
        q[typester's profile edit],
        '/{user}/profile/edit ok'
    );

    is( get('/typester/status/4423/remove'),
        q[typester's status: "4423" will remove],
        '/{user}/status/{status_id}/remove ok'
    );

    is( get('/typester/status/4423/update'),
        q[typester's status: "4423" will update],
        '/{user}/status/{status_id}/update ok'
    );
};
$tests->();

import Ark::Test 'T2', components => [qw/Controller::Root Controller::Status/],
    minimal_setup => 1;

$tests->();
