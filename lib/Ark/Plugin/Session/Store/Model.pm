package Ark::Plugin::Session::Store::Model;
use Ark::Plugin 'Session';

has store_model => (
    is      => 'rw',
    isa     => 'Object',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->app->model( $self->class_config->{model} || 'Session' );
    },
);

has store_model_key_prefix => (
    is      => 'rw',
    isa     => 'Str',
    default => sub {
        my $self = shift;
        defined $self->class_config->{key_prefix} ? $self->class_config->{key_prefix}
                                                  : 'session:';
    },
);

around 'get_session_data' => sub {
    my $next = shift;
    my ($self, $key) = @_;
    $key = $self->store_model_key_prefix . $key;

    if (my $session = $self->store_model->get($key)) {
        return $session;
    }

    $next->(@_);
};

around 'set_session_data' => sub {
    my $next = shift;
    my ($self, $key, $value) = @_;
    $key = $self->store_model_key_prefix . $key;

    if ( my $expire = $self->expire ) {
        $self->store_model->set( $key, $value, $expire );
    }
    else {
        $self->store_model->set( $key, $value );
    }
    $next->(@_);
};

around 'remove_session_data' => sub {
    my $next = shift;
    my ($self, $key) = @_;
    $key = $self->store_model_key_prefix . $key;

    $self->store_model->remove( $key );

    $next->(@_);
};

1;
