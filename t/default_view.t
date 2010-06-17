use Test::More;

{
    package T;
    use Ark;

    config default_view => 'MT';

    __PACKAGE__->meta->make_immutable;

    package T::View::MT;
    use Ark 'View::MT';
    __PACKAGE__->meta->make_immutable;

    package T::Controller::Root;
    use Ark 'Controller';

    has '+namespace' => default => '';

    sub index :Path {
        my ($self, $c) = @_;
        $c->res->body( ref $c->view );
    }

    __PACKAGE__->meta->make_immutable;
}

use Ark::Test 'T', components => [qw/Controller::Root View::MT/];

is get('/'), 'T::View::MT', 'default view config ok';
         
done_testing;
