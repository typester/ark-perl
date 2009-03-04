use Test::Base;
use FindBin;
use lib "$FindBin::Bin/lazy_component_loader/lib";

use Ark::Test 'TestApp', minimal_setup => 1;

plan 'no_plan';

my $res = get('/one');
is($res, 'view loaded', 'lazy view loader ok');
