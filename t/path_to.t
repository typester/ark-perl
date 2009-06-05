use Test::Base;
use FindBin;
use File::Spec;

use lib "$FindBin::Bin/path_to/lib";
use TestApp;

plan 'no_plan';

my $app = TestApp->new;
$app->setup;

is(File::Spec->canonpath($app->path_to->stringify), File::Spec->canonpath("$FindBin::Bin/path_to"), 'path_to ok');
