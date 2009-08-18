use Test::Base;

plan 'no_plan';

{
    package T;
    use Ark;

    package T::Controller::A;
    use Ark 'Controller';

    has '+namespace' => default => '';

    sub one :Path :Args(1) {
        my ($self, $c) = @_;
        $c->res->body('one');
    }

    sub two :Path :Args(2) {
        my ($self, $c) = @_;
        $c->res->body('two');
    }

    sub three :Path :Args(3) {
        my ($self, $c) = @_;
        $c->res->body('three');
    }

    sub zero :Path :Args(0) {
        my ($self, $c) = @_;
        $c->res->body('zero');
    }

    sub inf :Path :Args {
        my ($self, $c) = @_;
        $c->res->body('inf');
    }

    sub four :Path :Args(4) {
        my ($self, $c) = @_;
        $c->res->body('four');
    }

}

use Ark::Test 'T', components => [qw/Controller::A/];

ok get('/a'), 'one';
ok get('/a/b'), 'two';
ok get('/a/b/c'), 'three';
ok get('/'), 'zero';
ok get('/a/b/c/d/e/f/g'), 'inf';
ok get('/a/b/c/d'), 'four';

