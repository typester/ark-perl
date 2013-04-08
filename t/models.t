use Test::Base;
use FindBin;
use lib "$FindBin::Bin/models/lib";

plan 'no_plan';

use T::Models 'm1';
use T2::Models 'm2';
use T3::Models 'm3';

my $obj = m1('::Greetings');

isa_ok($obj, 'T::Models::Greetings');
is($obj->hello('hoge'), 'Hello, hoge', 'method ok');

is(m1('::Foo::Bar')->buzz, 'buzz!', 'deep path class ok');

is(m2('API::Hello')->hello, 'api hello!', 'custom nemespaces ok');

is(m3('Schema::Test')->test, 'test', 'autoloader ok');

