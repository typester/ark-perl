use Test::Base;
use FindBin;
use lib "$FindBin::Bin/form/lib";

plan 'no_plan';

use Ark::Test 'T';
use HTTP::Request::Common;

is(
    get('/login_form_input'),
    '<input name="username" type="text" />',
    'input method ok',
);

is(
    get('/login_form_render'),
    '<label for="id_username">Your Username</label><input id="id_username" name="username" type="text" />',
    'render method ok',
);

{
    my ($res, $c) = ctx_get('/login');
    isa_ok($c, 'Ark::Context');
    isa_ok(my $form = $c->stash->{form}, 'Ark::Form');

    ok(!$form->submitted, 'form is not submitted');
}

{
    my ($res, $c) = ctx_request(POST '/login', [ username => '', password => '' ]);
    isa_ok($c, 'Ark::Context');
    isa_ok(my $form = $c->stash->{form}, 'Ark::Form');

    ok($form->submitted, 'form is submitted');
    ok($form->has_error, 'form has errors');

    is(
        $form->error_message('username'),
        '<span class="error">Your Username is required</span>',
        'default error message ok 1',
    );
}

{
    my ($res, $c) = ctx_request(POST '/login', [ username => '日本', password => '' ]);
    my $form = $c->stash->{form};

    is(
        $form->error_message('username'),
        '<span class="error">Your Username is invalid</span>',
        'default error msg ok 2',
    );
}

{
    my ($res, $c) = ctx_request(POST '/login', [ password => '' ]);
    my $form = $c->stash->{form};

    is(
        $form->error_message_plain('password'),
        'password is required',
        'custom error msg ok 1',
    );
}

{
    my ($res, $c) = ctx_request(POST '/login', [ password => 'あああ' ]);
    my $form = $c->stash->{form};

    is(
        $form->error_message_plain('password'),
        'password must be ascii',
        'custom error msg ok 2',
    );

    is_deeply(
        $form->error_messages_plain('password'),
        [
            'password must be ascii',
            'password length must be 6-255',
        ],
        'error_messages ok'
    );
}

{
    my ( $res, $c )
        = ctx_request( POST '/login',
        [ username => 'user1', password => 'password4user1' ] );

    my $form = $c->stash->{form};

    ok($form->is_valid, 'form is valid ok');
}

{
    my ( $res, $c )
        = ctx_request( POST '/login',
        [ username => 'user1', password => 'password4user1_wrong' ] );

    my $form = $c->stash->{form};

    ok($form->has_error, 'form has error ok');
    is($form->error_message_plain('login'), 'username or password is wrong', 'custom validation ok');
}
