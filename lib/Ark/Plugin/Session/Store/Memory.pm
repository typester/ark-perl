package Ark::Plugin::Session::Store::Memory;
use Ark::Plugin 'Session';

my %session;

around 'get_session_data' => sub {
    my $next = shift;
    my ($self, $key) = @_;

    if (my $session = $session{$key}) {
        return $session;
    }

    $next->(@_);
};

around 'set_session_data' => sub {
    my $next = shift;
    my ($self, $key, $value) = @_;

    $session{$key} = $value;

    $next->(@_);
};

around 'remove_session_data' => sub {
    my $next = shift;
    my ($self, $key) = @_;

    delete $session{$key};

    $next->(@_);
};

1;
