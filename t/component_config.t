use strict;
use warnings;
use Test::More;

{
    package TestApp;
    use Ark;

    __PACKAGE__->config(
        'Controller::Three' => {
            namespace => 'three_changed',
        },
    );

    package TestApp::Controller::One;
    use Ark 'Controller';

    has '+namespace' => default => 'one_changed';

    sub index :Path {
        my ($self, $c) = @_;
        $c->res->body('one');
    }

    package TestApp::Controller::Two;
    use Ark 'Controller';

#    __PACKAGE__->config( namespace => 'two_changed' );

    sub index :Path {
        my ($self, $c) = @_;
        $c->res->body('two');
    }

    package TestApp::Controller::Three;
    use Ark 'Controller';

    sub index :Path {
        my ($self, $c) = @_;
        $c->res->body('three');
    }

}


use Ark::Test 'TestApp',
    components => [qw/Controller::One
                      Controller::Two
                      Controller::Three
                     /];

is(get('/one_changed'), 'one', 'one ok');

# no more supported
#is(get('/two_changed'), 'two', 'two ok');
#is(get('/three_changed'), 'three', 'three ok');

done_testing;
