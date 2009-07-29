package T::Form::Login;
use Ark 'Form';
use T::Models;

param username => (
    type        => 'TextField',
    label       => 'Your Username',
    constraints => ['NOT_NULL', 'ASCII'],
);

param password => (
    type        => 'PasswordField',
    label       => 'Your Password',
    constraints => ['NOT_NULL', 'ASCII', ['LENGTH', 6, 255]],
    messages    => {
        not_null => 'password is required',
        ascii    => 'password must be ascii',
        length   => 'password length must be 6-255',
    },
);

sub custom_validation {
    my ($self, $form) = @_;
    return if $form->has_error;

    my $user = models('users')->find(
        username => $form->param('username'),
        password => $form->param('password'),
    );

    unless ($user) {
        $form->set_error( login => 'failed' );
    }
}

sub messages {
    return {
        %{ shift->SUPER::messages },
        'login.failed' => 'username or password is wrong',
    };
}

1;
