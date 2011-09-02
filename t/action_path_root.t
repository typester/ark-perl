use Test::More;

use FindBin;
use lib "$FindBin::Bin/action_path_root/lib";

use Ark::Test 'TestApp';

{
    my $res = request( GET => '/' );
    ok $res, 'response ok';
    is $res->code, '200', '200 ok';
    is $res->content, 'root', 'root dispatch ok';
}

{
    my $res = request( GET => '/foo' );
    ok $res, 'response ok';
    is $res->code, '200', '200 ok';
    is $res->content, 'foo', 'foo dispatch ok';
}

done_testing;
