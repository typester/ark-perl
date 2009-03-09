use Test::Base;

{
    package TestApp;
    use Ark;

    __PACKAGE__->load_plugins('Session');
    __PACKAGE__->config(
        'Plugin::Session' => {
            state => {
                class => 'Cookie',
                args => {
                    name => 'test_session_cookie_name',
                },
            },
            store => {
                class => 'OnMemory',
                args  => { data => {} },
            },
        },
    );

    package TestApp::Controller::Root;
    use Ark 'Controller';

    has '+namespace' => default => '';

    sub test :Local {
        my ($self, $c) = @_;
        $c->session->set('test', 'dummy');
    }

    sub incr :Local {
        my ($self, $c) = @_;

        my $count = $c->session->get('count') || 0;
        $c->session->set( count => ++$count );

        $c->res->body( $count );
    }
}

plan 'no_plan';

use Ark::Test 'TestApp',
    components       => [qw/Controller::Root/],
    reuse_connection => 1;

my $cookie;
{
    my $res = request(GET => '/test');
    like( $res->header('Set-Cookie'), qr/test_session_cookie_name=/, 'session id ok');
    ($cookie) = $res->header('Set-Cookie') =~ /test_session_cookie_name=(.*?);/;
}

{
    my $req = HTTP::Request->new( GET => '/incr' );
    $req->header( Cookie => 'test_session_cookie_name=' . $cookie );

    is(request($req)->content, 1, 'increment first ok');
    is(request($req)->content, 2, 'increment second ok');
}
