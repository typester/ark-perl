package Ark::Plugin::Authentication::Store::Model;
use Ark::Plugin 'Auth';

has store_model => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->class_config->{model};
    },
);

around find_user => sub {
    my $prev = shift->(@_);
    return $prev if $prev;

    my ($self, $id, $info) = @_;

    my $model = $self->app->model( $self->store_model );
    if (my $user = $model->find_user($id, $info)) {
        $self->ensure_class_loaded('Ark::Plugin::Authentication::User');

        unless ($user->{hash} && $user->{obj_builder}) {
            $user = {
                hash        => $user,
                obj_builder => sub { $user },
            };
        }

        return Ark::Plugin::Authentication::User->new(
            %$user,
            store => 'Model',
        );
    }

    return;
};

around from_session => sub {
    my $prev = shift->(@_);
    return $prev if $prev;

    my ($self, $user) = @_;

    return unless $user->{store} eq 'Model';

    my $model = $self->app->model( $self->store_model );

    if ($model->can('from_session')) {
        $user = $model->from_session($user);
        unless ($user->{hash} && $user->{obj_builder}) {
            $user = {
                hash        => $user,
                obj_builder => sub { $user },
            };
        }
    }
    else {
        $user->{obj_builder} = sub { $user->{hash} };
    }

    return Ark::Plugin::Authentication::User->new(
        %$user,
        store => 'Model',
    );
};

1;
