use Test::Base;
use FindBin;
use lib "$FindBin::Bin/lazy_action_loader/lib";

use TestApp;

use Ark::Test 'TestApp', minimal_setup => 1;

plan 'no_plan';

{
    my $res = get('/one');
    is($res, '/one/index', 'lazy request ok');
}

{
    my $res = get('/two');
    is($res, '/two/index', 'lazy request ok');
}
