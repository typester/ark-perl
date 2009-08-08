use Test::Base;
use FindBin;
use lib "$FindBin::Bin/models/lib";

plan 'no_plan';

use T::Models 'm1';
use T2::Models 'm2';

my $obj = m1('::greetings');

isa_ok($obj, 'T::Models::Greetings');
is($obj->hello('hoge'), 'Hello, hoge', 'method ok');

is(m1('::foo::bar')->buzz, 'buzz!', 'deep path class ok');

is(m2('api::hello')->hello, 'api hello!', 'custom nemespaces ok');
