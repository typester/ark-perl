package Ark::Plugin::Session;
use Ark::Plugin;

has session => (
    is      => 'rw',
    isa     => 'Ark::Plugin::Session::Backend',
    lazy    => 1,
    default => sub {
        my $self = shift;

        my $conf  = $self->app->config->{'Plugin::Session'} || {};

        $self->app->ensure_class_loaded('Ark::Plugin::Session::Backend');
        my $class = $self->app->class_wrapper(
            name => 'Session',
            base => 'Ark::Plugin::Session::Backend',
        );

        $class->new(%$conf, app => $self->app);
    },
);

before finalize => sub {
    my $context = shift;
    return unless $context->{session};
    $context->session->finalize_session( $context->response );
};

1;
