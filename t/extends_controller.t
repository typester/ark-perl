use strict;
use warnings;
use Test::More;

{
    package T;
    use Ark;

    package T::Controller::Base;
    use Ark 'Controller';

    sub foo :Private {
        my ($self, $c) = @_;
        $c->res->body('foo');
    }

    package T::Controller::Root;
    use Ark '+T::Controller::Base';

    has '+namespace' => default => '';

    sub test :Local {
        my ($self, $c) = @_;
        $c->forward('foo');
    }
}


use Ark::Test 'T',
    components => [qw/Controller::Root/];

is(get('/test'), 'foo', 'extends controller ok');

done_testing;
