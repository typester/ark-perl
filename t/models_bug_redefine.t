use strict;
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/models/lib";


{
    package Foo;
    use T::Models;

    package Bar;
    use base 'Foo';
    use T::Models;
}

pass 'compile ok';

done_testing;
