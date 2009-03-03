use Test::Base;
use FindBin;

use lib "$FindBin::Bin/path_to/lib";
use TestApp;

plan 'no_plan';

my $app = TestApp->new;
$app->setup;

is($app->path_to->stringify, "$FindBin::Bin/path_to", 'path_to ok');
