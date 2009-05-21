package Ark::Plugin::Session::Store::Model;
use Ark::Plugin 'Session';

has model => (
    is      => 'rw',
    isa     => 'Object',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->app->model( $self->class_config->{model} || 'Session' );
    },
);

around 'get_session_data' => sub {
    my $next = shift;
    my ($self, $key) = @_;

    if (my $session = $self->model->get($key)) {
        return $session;
    }

    $next->(@_);
};

around 'set_session_data' => sub {
    my $next = shift;
    my ($self, $key, $value) = @_;

    $self->model->set( $key, $value );

    $next->(@_);
};

around 'remove_session_data' => sub {
    my $next = shift;
    my ($self, $key) = @_;

    $self->model->remove( $key );

    $next->(@_);
};

1;
