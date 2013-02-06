use strict;
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/plugin_i18n/lib";

eval "require Locale::Maketext::Lexicon; require Locale::Maketext::Simple; 1";
plan skip_all => 'Locale::Maketext::Lexicon required to run this test' if $@;

use Ark::Test 'TestApp::SubApp';
use HTTP::Request::Common;

my $req = GET '/hello';
$req->header('Accept-Language' => 'ja' );

my $res = request $req;

is $res->code, '200';
is $res->content, 'こんにちは';

done_testing;

