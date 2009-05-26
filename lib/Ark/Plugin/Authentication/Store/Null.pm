package Ark::Plugin::Authentication::Store::Null;
use Ark::Plugin 'Auth';

around find_user => sub {
    my $prev = shift->(@_);
    return $prev if $prev;

    my ($self, $id, $info) = @_;

    $self->ensure_class_loaded('Ark::Plugin::Authentication::User');
    return Ark::Plugin::Authentication::User->new(
        hash        => $info,
        obj_builder => sub { $info },
        store       => 'Null',
    );

    return;
};

around from_session => sub {
    my $prev = shift->(@_);
    return $prev if $prev;

    my ($self, $user) = @_;

    return unless $user->{store} eq 'Null';

    $self->ensure_class_loaded('Ark::Plugin::Authentication::User');
    Ark::Plugin::Authentication::User->new(
        hash        => $user->{hash},
        obj_builder => sub { $user->{hash} },
        store       => 'Null',
    );
};

1;
