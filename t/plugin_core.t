use Test::Base;

plan 'no_plan';

{
    package App::Plugin::ExtendArkCore;
    use Ark::Plugin 'Core';

    around handle_request => sub {
        my $next = shift;
        my ($self, $req) = @_;

        my $res = $next->(@_);

        $res->body('handled by plugin');

        $res;
    };

    package App;
    use Ark;

    use_plugins qw/+App::Plugin::ExtendArkCore/;
}

use Ark::Test 'App';

is(get('/'), 'handled by plugin', 'core plugin ok');

