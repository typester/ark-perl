use Test::Base;

{
    package TestApp;
    use Ark;

    use_plugins 'Encoding::Unicode';

    package TestApp::Controller::Root;
    use Ark 'Controller';

    has '+namespace' => default => '';

    sub default :Path {
        my ($self, $c) = @_;

        my $test = 'テスト';
        Test::More::ok( utf8::is_utf8($test), 'utf8 flag automatically on by Ark' );

        Test::More::ok(utf8::is_utf8( $c->req->params->{foo} ), 'request is utf8');
        Test::More::is($c->req->params->{foo}, $test, 'request ok');

        $c->res->body( $c->req->params->{foo} );
    }
}

use Ark::Test 'TestApp',
    components => [qw/Controller::Root/];

plan 'no_plan';

use URI;
my $uri = URI->new('/');
$uri->query_form({ foo => 'テスト' });

my $res = request( GET => $uri );
ok($res->is_success, 'request ok');
ok(!utf8::is_utf8($res->content), 'response is binary');
is($res->content, 'テスト', 'response content ok');

