use strict;
use warnings;
use Test::More;

{
    package T1;
    use Ark;

    use_plugins qw/
        Session
        Session::State::Cookie
        Session::Store::Memory

        Authentication
        Authentication::Credential::Password
        Authentication::Store::Minimal
        /;

    conf 'Plugin::Authentication::Store::Minimal' => {
        users => {
            user1 => { username => 'user1', password => 'pass1', },
            user2 => { username => 'user2', password => 'pass2', },
        },
    };

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

    sub logout :Local {
        my ($self, $c) = @_;

        $c->logout;
        $c->res->body('logouted');
    }
}


use Ark::Test 'T1',
    components => [qw/Controller::Root/],
    reuse_connection => 1;

is(get('/'), 'require login', 'not login ok');
is(get('/login'), 'login done', 'login ok');
is(get('/'), 'logined: user1', 'logined ok');
is(get('/logout'), 'logouted', 'logout ok');
is(get('/'), 'require login', 'not login after logout ok');
done_testing;
