package Ark::Plugin::Authentication::Store::DBIx::Class;
use Ark::Plugin 'Auth';

has dbix_class_model => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->class_config->{model} || 'DBIC';
    },
);

has dbix_class_resultset => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->class_config->{resultset} || 'User';
    },
);

has dbix_class_user_field => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->class_config->{user_field} || 'username';
    },
);

around find_user => sub {
    my $prev = shift->(@_);
    return $prev if $prev;

    my ($self, $id, $info) = @_;

    my $model = $self->app->model( $self->dbix_class_model );
    my $rs    = $model->resultset( $self->dbix_class_resultset );

    my $user;
    if ($rs->can('find_user')) {
        $user = $rs->find_user($id, $info);
    }
    else {
        $user = $rs->single({ $self->dbix_class_user_field => $id })
    }

    if ($user) {
        $self->ensure_class_loaded('Ark::Plugin::Authentication::User');

        return Ark::Plugin::Authentication::User->new(
            store => 'DBIx::Class',
            obj   => $user,
            hash  => { $user->get_columns },
        );
    }

    return;
};

around 'from_session' => sub {
    my $prev = shift->(@_);
    return $prev if $prev;

    my ($self, $user) = @_;

    return unless $user->{store} eq 'DBIx::Class';

    $self->ensure_class_loaded('Ark::Plugin::Authentication::User');

    Ark::Plugin::Authentication::User->new(
        store       => 'DBIx::Class',
        hash        => $user->{hash},
        obj_builder => sub {
            my $model = $self->app->model( $self->dbix_class_model );
            my $rs    = $model->resultset( $self->dbix_class_resultset );

            $rs->single({
                $self->dbix_class_user_field =>
                        $user->{hash}{ $self->dbix_class_user_field }
            });
        },
    );
};

1;

