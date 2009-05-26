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
    my $prev = shift->(@_);
    return $prev if $prev;

    my ($self, $id, $info) = @_;

    if (my $user = $self->store_minimal_users->{ $id }) {
        $self->ensure_class_loaded('Ark::Plugin::Authentication::User');
        return Ark::Plugin::Authentication::User->new(
            hash        => $user,
            obj_builder => sub { $user },
            store       => 'Minimal'
        );
    }

    return;
};

around 'from_session' => sub {
    my $prev = shift->(@_);
    return $prev if $prev;

    my ($self, $user) = @_;

    return unless $user->{store} eq 'Minimal';

    $self->ensure_class_loaded('Ark::Plugin::Authentication::User');
    Ark::Plugin::Authentication::User->new(
        obj_builder => sub { $user->{hash} },
        hash        => $user->{hash},
        store       => 'Minimal',
    );
};

1;
