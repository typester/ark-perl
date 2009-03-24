package Ark::Plugin::Authentication::Store::Null;
use Ark::Plugin 'Auth';

around find_user => sub {
    my $next = shift;
    my ($self, $id, $info) = @_;

    $self->ensure_class_loaded('Ark::Plugin::Authentication::User');
    return Ark::Plugin::Authentication::User->new(
        obj   => $info,
        store => 'Null',
    );

    $next->(@_);
};

around for_session => sub {
    my $next = shift;
    my ($self, $user) = @_;

    if ($user && $user->store eq 'Null') {
        return {
            hash  => $user->hash,
            store => $user->store,
        };
    }

    $next->(@_);
};

sub from_session {
    my $self = shift;

    my $user = $self->context->session->get('__user') or return;

    return unless ref $user eq 'HASH';
    return unless $user->{store} eq 'Null';
    return unless $user->{hash} && ref $user->{hash} eq 'HASH';

    $self->ensure_class_loaded('Ark::Plugin::Authentication::User');
    Ark::Plugin::Authentication::User->new(
        obj => $user->{hash},
        store => 'Null',
    );
}

around restore_user => sub {
    my $next = shift;
    my ($self) = @_;

    if (my $user = $self->method('from_session')->()) {
        return $user;
    }

    $next->(@_);
};

1;
