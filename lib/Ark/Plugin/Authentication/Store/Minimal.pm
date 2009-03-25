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
            hash        => $user,
            obj_builder => sub { $user },
            store       => 'Minimal'
        );
    }

    $next->(@_);
};

around 'from_session' => sub {
    my $next = shift;
    my ($self, $user) = @_;

    return $next->(@_) unless $user->{store} eq 'Minimal';

    $self->ensure_class_loaded('Ark::Plugin::Authentication::User');
    Ark::Plugin::Authentication::User->new(
        obj_builder => sub { $user->{hash} },
        hash        => $user->{hash},
        store       => 'Minimal',
    );
};

1;
