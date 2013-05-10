use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lazy_component_loader/lib";

use Ark::Test 'TestApp', minimal_setup => 1;


my $res = get('/one');
is($res, 'view loaded', 'lazy view loader ok');
done_testing;
