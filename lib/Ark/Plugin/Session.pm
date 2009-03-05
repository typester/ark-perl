package Ark::Plugin::Session;
use Ark::Plugin;

# TODO: multiple state

has session => (
    is      => 'rw',
    isa     => 'HTTP::Session',
    lazy    => 1,
    default => sub {
        my $self = shift;

        my $conf = $self->app->config->{'Plugin::Session'} || {};

        my $state = do {
            my $class = $conf->{state}{class} or die "Require set session state class";
            $self->ensure_class_loaded($class = "HTTP::Session::State::${class}");
            $class->new( $conf->{state}{args} || () );
        };

        my $store = do {
            my $class = $conf->{store}{class} or die "Require set session store class";
            $self->ensure_class_loaded($class = "HTTP::Session::Store::${class}");
            $class->new( $conf->{store}{args} || () );
        };

        $self->ensure_class_loaded('HTTP::Session');

        HTTP::Session->new(
            state   => $state,
            store   => $store,
            request => $self->request,
        );
    },
);

after finalize => sub {
    my $self = shift;

    my $session = $self->{session} or return;
    $session->response_filter($self->response);
};

1;

