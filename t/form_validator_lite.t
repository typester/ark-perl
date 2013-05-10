use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/form_validator_lite/lib";


use Ark::Test 'T';
use HTTP::Request::Common;

{
    my ($res, $c) = ctx_get('/login');
    isa_ok($c, 'Ark::Context');
    isa_ok(my $form = $c->validator, "FormValidator::Lite");
}

done_testing;
