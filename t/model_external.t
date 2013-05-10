use strict;
use warnings;
use Test::More;
use File::Temp qw/tempdir/;


BEGIN { $ENV{ARK_HOME} = tempdir( CLEANUP => 1 ) }

{
    package T::Models;
    use base 'Ark::Models';

    package T;
    use Ark;

    use_model 'T::Models';

    package T::Controller::Root;
    use Ark 'Controller';
    T::Models->import; # use T::Models;

    has '+namespace' => default => '';

    sub index :Path :Args(0) {
        my ($self, $c) = @_;
        my $foo = $c->model('foo');
        $c->res->body( $foo->{foo} );
    }
}

use Ark::Test 'T', components => [qw/Controller::Root/];

T::Models->register( foo => sub { bless { foo => 'bar' }, 'Foo' } );

is( get('/'), 'bar', 'model replacement ok' );

ok( T::Models->get('home'), 'home is defined ok' );
isa_ok( T::Models->get('home'), 'Path::Class::Dir');
done_testing;
