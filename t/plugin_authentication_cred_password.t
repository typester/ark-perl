use strict;
use warnings;
use Test::More;

{
    package T1;
    use Ark;

    use Digest::SHA1 'sha1_hex';

    use_plugins qw/
        Session
        Session::State::Cookie
        Session::Store::Memory

        Authentication
        Authentication::Credential::Password
        Authentication::Store::Minimal
        /;

    conf 'Plugin::Authentication::Credential::Password' => {
        password_type      => 'hashed',
        password_pre_salt  => 'pre',
        password_post_salt => 'post',
    };

    conf 'Plugin::Authentication::Store::Minimal' => {
        users => {
            user1 => {
                username => 'user1', password => sha1_hex('pre'.'pass1'.'post'),
            },
            user2 => {
                username => 'user2', password => sha1_hex('pre'.'pass2'.'post'),
            },
        },
    };

    package T1::Model::Digest;
    use Ark 'Model::Adaptor';

    __PACKAGE__->config( class => 'Digest::SHA1' );

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
                      Model::Digest
                     /],
    reuse_connection => 1;


is(get('/'), 'require login', 'not login ok');
is(get('/login'), 'login done', 'login ok');
is(get('/'), 'logined: user1', 'logined ok');
done_testing;
