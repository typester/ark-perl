use strict;
use warnings;
use Test::More;
use File::Temp;

BEGIN {
    eval "use DBI; use DBIx::Class::Schema::Loader";
    plan skip_all => 'DBIx::Class::Schema::Loader required to run this test' if $@;
}

my $db = "testdatabase";
END { unlink $db }

{
    # create Database
    my $dbh = DBI->connect("dbi:SQLite:dbname=$db")
        or die DBI->errstr;

    $dbh->do(<<'...');
CREATE TABLE user (
    id INTEGER NOT NULL PRIMARY KEY,
    username TEXT NOT NULL,
    password TEXT NOT NULL
);
...

    $dbh->do(<<'...');
INSERT INTO user (username, password) values ('user1', 'pass1');
...


    $dbh->do(<<'...');
INSERT INTO user (username, password) values ('user2', 'pass2');
...

}

{
    package T1::Schema;
    use base qw/DBIx::Class::Schema::Loader/;
    __PACKAGE__->loader_options;
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
        Authentication::Store::DBIx::Class
        /;

    package T1::Model::DBIC;
    use Ark 'Model::Adaptor';

    __PACKAGE__->config(
        class       => 'T1::Schema',
        constructor => 'connect',
        deref       => 1,
        args        => ["dbi:SQLite:dbname=$db"],
    );

    package T1::Controller::Root;
    use Ark 'Controller';

    has '+namespace' => default => '';

    sub index :Path {
        my ($self, $c) = @_;

        if ($c->user && $c->user->authenticated) {
            $c->res->body( 'logined: ' . $c->user->obj->username );
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
                      Model::DBIC
                     /],
    reuse_connection => 1;


is(get('/'), 'require login', 'not login ok');
is(get('/login'), 'login done', 'login ok');
is(get('/'), 'logined: user1', 'logined ok');

done_testing;
