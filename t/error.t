use Test::Base;

plan 'no_plan';

{
    package T;
    use Ark;

    package T::Controller::Root;
    use Ark 'Controller';

    has '+namespace' => default => '';

    sub index :Path {
        my ($self, $c) = @_;
        die;
    }
}

use Ark::Test 'T', components => [qw/Controller::Root/];

my ($res, $c) = ctx_request(GET => '/');
is($res->code, 500, '500 ok');
is($res->content, 'Internal Server Error', 'error content ok');
like($c->error->[-1], qr/^Died at/, 'error msg ok');

