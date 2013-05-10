use strict;
use warnings;
use Test::More;

{
    package T1::UserDB;
    use Mouse;

    has users => (
        is => 'rw',
        isa => 'HashRef',
        default => sub {
            {
                user1 => {
                    username => 'user1',
                    password => 'pass1',
                },
            },
        },
    );

    sub find_user {
        my ($self, $id, $info) = @_;
        $self->users->{$id};
    }
}

{
    package T1;
    use Ark;

    use_plugins qw/
        Session
        Session::State::Cookie
        Session::Store::Memory

        Authentication
        Authentication::Credential::Password
        Authentication::Store::Model
        /;

    conf 'Plugin::Authentication::Store::Model' => {
        model => 'UserDB',
    };

    package T1::Model::UserDB;
    use Ark 'Model::Adaptor';

    __PACKAGE__->config(
        class => 'T1::UserDB',
    );

    package T1::Controller::Root;
    use Ark 'Controller';

    has '+namespace' => default => '';

    sub index :Path {
        my ($self, $c) = @_;

        if ($c->user && $c->user->authenticated) {
            $c->res->body( 'logined: ' . $c->user->obj->{username} );
        }
        else {
            $c->res->body( 'require login' );
        }
    }

    sub login :Local {
        my ($self, $c) = @_;

        if (my $user = $c->authenticate({ username => 'user1', password => 'pass1' })) {
            $c->res->body( 'login done' );
        }
    }
}


use Ark::Test 'T1',
    components => [qw/Controller::Root
                      Model::UserDB
                     /],
    reuse_connection => 1;


is(get('/'), 'require login', 'not login ok');
is(get('/login'), 'login done', 'login ok');
is(get('/'), 'logined: user1', 'logined ok');

done_testing;
