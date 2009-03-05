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
            store => { class => 'OnMemory' },
        },
    );

    package TestApp::Controller::Root;
    use Ark 'Controller';

    has '+namespace' => default => '';

    sub test :Local {
        my ($self, $c) = @_;
        $c->session->set('test', 'dummy');
    }
}

plan 'no_plan';

use Ark::Test 'TestApp',
    components => [qw/Controller::Root/];

{
    my $res = request(GET => '/test');
    like( $res->header('Set-Cookie'), qr/test_session_cookie_name=/, 'session id ok')
}


