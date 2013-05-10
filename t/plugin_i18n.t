use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/plugin_i18n/lib";

eval "require Locale::Maketext::Lexicon; require Locale::Maketext::Simple; 1";
plan skip_all => 'DBIx::Class::Schema::Loader required to run this test' if $@;


use Ark::Test 'TestApp';

# test Lexicon
{
    my $expected = 'Bonjour';
    my $request  =
        HTTP::Request->new( GET => '/maketext/Hello' );

    $request->header( 'Accept-Language' => 'fr' );

    ok( my $response = request($request), 'Request' );
    ok( $response->is_success, 'Response Successful 2xx' );
    is( $response->code, 200, 'Response Code' );

    is( $response->content, $expected, 'Content OK' );
}

# test .po
{
    my $expected = 'Hallo';
    my $request  =
        HTTP::Request->new( GET => '/maketext/Hello' );

    $request->header( 'Accept-Language' => 'de' );

    ok( my $response = request($request), 'Request' );
    ok( $response->is_success, 'Response Successful 2xx' );
    is( $response->code, 200, 'Response Code' );

    is( $response->content, $expected, 'Content OK' );
}

# test language()
{
    my $expected = 'fr';
    my $request  =
        HTTP::Request->new( GET => '/current_language' );

    $request->header( 'Accept-Language' => 'fr' );

    ok( my $response = request($request), 'Request' );
    ok( $response->is_success, 'Response Successful 2xx' );
    is( $response->code, 200, 'Response Code' );

    is( $response->content, $expected, 'Content OK' );
}

# test fallback (i.e. fr-ca => fr)
{
    my $expected = 'fr';
    my $request  =
        HTTP::Request->new( GET => '/current_language' );

    $request->header( 'Accept-Language' => 'fr-ca' );

    ok( my $response = request($request), 'Request' );
    ok( $response->is_success, 'Response Successful 2xx' );
    is( $response->code, 200, 'Response Code' );

    is( $response->content, $expected, 'Content OK' );
}
done_testing;
