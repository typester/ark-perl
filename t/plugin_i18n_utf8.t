use utf8;
use Test::Base;
use FindBin;
use lib "$FindBin::Bin/plugin_i18n/lib";

eval "require Locale::Maketext::Lexicon; require Locale::Maketext::Simple; 1";
plan skip_all => 'Locale::Maketext::Lexicon and Locale::Maketext::Simple required to run this test' if $@;

plan 'no_plan';

use Ark::Test 'TestApp';
use Encode;

# test Lexicon
{
    my $expected = 'Bonjour';
    my $request  =
        HTTP::Request->new( GET => '/maketext/Hello' );

    $request->header( 'Accept-Language' => 'ja' );

    ok( my ($response, $c) = ctx_request($request), 'Request' );
    ok( $response->is_success, 'Response Successful 2xx' );
    is( $response->code, 200, 'Response Code' );
    is( $response->content, encode_utf8('こんにちは'), 'response encoded ok');

    is(utf8::is_utf8($c->stash->{body}), 1, 'utf-8 flagged ok');

    # also with arguments
    my $r = $c->localize('logined as [_1]', '名無し');
    is $r, '名無し としてログインしています', 'localize response ok';
    is utf8::is_utf8($r), 1, 'utf-8 ok';
    
}

