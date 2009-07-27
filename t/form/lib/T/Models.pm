package T::Models;
use strict;
use warnings;
use Ark::Models -Base;

{
    package T::Users;
    use Mouse;

    our %users = (
        user1 => { password => 'password4user1', },
    );

    sub find {
        my ($self, %info) = @_;

        my $user = $users{ $info{username} } or return;

        if ($user->{password} eq $info{password}) {
            return $user;
        }
        return;
    }
}

register users => sub {
    T::Users->new;
};

