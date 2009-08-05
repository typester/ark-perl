use Test::Base;

plan 'no_plan';

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


