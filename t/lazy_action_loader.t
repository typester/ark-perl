use strict;
use warnings;
use Test::More;

plan 'no_plan';

use FindBin;
use lib "$FindBin::Bin/lazy_action_loader/lib";

use Ark::Test 'TestApp', minimal_setup => 1;


{
    my $res = get('/one');
    is($res, '/one/index', 'lazy request ok');
}

{
    my $res = get('/two');
    is($res, '/two/index', 'lazy request ok');
}
