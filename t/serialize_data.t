use Test::Base;

use FindBin;
use lib "$FindBin::Bin/serialize_data/lib";

use TestApp;

plan 'no_plan';

my $app = TestApp->new;
$app->setup_home;

# remove cache file if it already exists
my $cache = $app->path_to('action.cache');
$cache->remove if -e $cache;

$app->setup_minimal;

ok($app->setup_finished, 'minimal setup finished');
ok(-f $cache && -s _, 'cache file created');


my $app2 = TestApp->new;
$app2->setup_minimal;

ok($app->actions->{""}, 'action container loaded ok');
ok($app->actions->{""}->actions->{default}, 'default action loaded ok');

$cache->remove;

