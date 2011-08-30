use Test::Base;
use FindBin;
use lib "$FindBin::Bin/form_validator_lite/lib";

plan 'no_plan';

use Ark::Test 'T';
use HTTP::Request::Common;

{
    my ($res, $c) = ctx_get('/login');
    isa_ok($c, 'Ark::Context');
    isa_ok(my $form = $c->validator, "FormValidator::Lite");
}

