use strict;
use warnings;
use Test::More;
use FindBin;
use File::Spec;

use lib "$FindBin::Bin/path_to/lib";
use TestApp;


my $app = TestApp->new;
$app->setup;

is(File::Spec->canonpath($app->path_to->stringify), File::Spec->canonpath("$FindBin::Bin/path_to"), 'path_to ok');
done_testing;
