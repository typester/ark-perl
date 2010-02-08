use Test::More;

{
    package T;
    use Ark;

    use_plugins qw{
        Session
        Session::State::OpenSocial
        Session::Store::Memory
    };

    package T::Controller::Root;
    use Ark 'Controller';

    has '+namespace' => default => '';

    sub counter :Local {
        my ($self, $c) = @_;

        my $count = $c->session->get('counter') || 0;
        $c->session->set( counter => ++$count );

        $c->res->body($count);
    }
}

use Ark::Test 'T',
    components => [qw/Controller::Root/],
    reuse_conneciton => 1;

is get('/counter?opensocial_owner_id=foo'), 1, 'user1 counter 1 ok';
is get('/counter?opensocial_owner_id=foo'), 2, 'user1 counter 2 ok';

is get('/counter?opensocial_owner_id=bar'), 1, 'user2 counter 1 ok';
is get('/counter?opensocial_owner_id=bar'), 2, 'user2 counter 2 ok';



done_testing;
