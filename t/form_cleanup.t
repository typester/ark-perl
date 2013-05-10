use Test::Base;
use FindBin;
use lib "$FindBin::Bin/form/lib";

plan 'no_plan';

use Ark::Test 'T', 'reuse_connection' => 1;
use HTTP::Request::Common;

is(
    get('/login_form_input'),
    '<input name="username" type="text" />',
    'input method ok',
);

{
    my $res = request GET '/';
    like $res->content, qr/OK/, '$self->form is empty';
}
