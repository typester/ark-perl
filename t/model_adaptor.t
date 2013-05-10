use strict;
use warnings;
use Test::More;

{
    package MyClass;
    use Mouse;

    sub hello { 'hello adaptor' }

    package MyHello;
    use Mouse;

    has target => (
        is       => 'rw',
        isa      => 'Str',
        required => 1,
    );

    sub hello { 'hello ' . shift->target }


    package TestApp;
    use Ark;

    package TestApp::Controller::Root;
    use Ark 'Controller';

    has '+namespace' => default => '';

    sub myclass :Local {
        my ($self, $c) = @_;
        $c->res->body(
            $c->model('MyClass')->hello
        );
    }

    sub hellome :Local {
        my ($self, $c) = @_;
        $c->res->body(
            $c->model('MyHello')->hello
        );
    }

    package TestApp::Model::MyClass;
    use Ark 'Model::Adaptor';

    has '+class' => default => 'MyClass';

    package TestApp::Model::MyHello;
    use Ark 'Model::Adaptor';

    __PACKAGE__->config(
        class => 'MyHello',
        args  => {
            target => 'typester',
        },
    );
}


use Ark::Test 'TestApp',
    components => [qw/Controller::Root
                      Model::MyClass
                     /];

is(get('/myclass'), 'hello adaptor', 'adaptor response ok');
is(get('/hellome'), 'hello typester', 'adaptor with args ok');
done_testing;
