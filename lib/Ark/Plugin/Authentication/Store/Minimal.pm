package Ark::Plugin::Authentication::Store::Minimal;
use Ark::Plugin 'Auth';

has store_minimal_users => (
    is      => 'rw',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->class_config->{'users'} || {};
    },
);

around find_user => sub {
    my $next = shift;
    my ($self, $id, $info) = @_;

    if (my $user = $self->store_minimal_users->{ $id }) {
        $self->ensure_class_loaded('Ark::Plugin::Authentication::User');
        return Ark::Plugin::Authentication::User->new(
            obj   => $user,
            store => 'Minimal'
        );
    }

    $next->(@_);
};

around for_session => sub {
    my $next = shift;
    my ($self, $user) = @_;

    if ($user && $user->store eq 'Minimal') {
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
    return unless $user->{store} eq 'Minimal';
    return unless $user->{hash} && ref $user->{hash} eq 'HASH';

    $self->ensure_class_loaded('Ark::Plugin::Authentication::User');
    Ark::Plugin::Authentication::User->new(
        obj => $user->{hash},
        store => 'Minimal',
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
