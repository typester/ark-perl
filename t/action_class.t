use Test::Base;

plan 'no_plan';

{
    package T;
    use Ark;

    package T::ActionClass::Foo;
    use Mouse::Role;

    around ACTION => sub {
        my $next = shift;
        my ($controller, $action, @args) = @_;

        my $r = $controller->context->response;
        $r->body( 'before' );

        my $res = $next->(@_);

        $r->body( $r->body . 'after' );

        $res;
    };

    package T::Controller::MyBase;
    use Ark 'Controller';

    with 'T::ActionClass::Foo';

    package T::Controller::Root;
    use Ark '+T::Controller::MyBase';

    has '+namespace' => default => '';

    sub index :Path :Args(0) {
        my ($self, $c) = @_;

        $c->res->body( $c->res->body . 'action' );
    }
}


use Ark::Test 'T', components => [
    qw/
        ActionClass::Foo
        Controller::MyBase
        Controller::Root
        /
];

is(get('/'), 'beforeactionafter', 'action class ok');

