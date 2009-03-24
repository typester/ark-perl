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
    my $next = shift;
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
        $self->ensure_class_loaded(
            'Ark::Plugin::Authentication::Store::DBIx::Class::User');

        return Ark::Plugin::Authentication::Store::DBIx::Class::User->new(
            store => 'DBIx::Class',
            obj   => $user,
            hash  => { $user->get_columns },
        );
    }

    $next->(@_);
};

around for_session => sub {
    my $next = shift;
    my ($self, $user) = @_;

    if ($user && $user->store eq 'DBIx::Class') {
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
    return unless $user->{store} eq 'DBIx::Class';
    return unless $user->{hash} && ref $user->{hash} eq 'HASH';

    $self->ensure_class_loaded(
        'Ark::Plugin::Authentication::Store::DBIx::Class::User');

    return Ark::Plugin::Authentication::Store::DBIx::Class::User->new(
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
