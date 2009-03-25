package Ark::Plugin::Authentication;
use Ark::Plugin;

has auth => (
    is      => 'rw',
    isa     => 'Ark::Plugin::Authentication::Backend',
    lazy    => 1,
    default => sub {
        my $self = shift;

        my $conf = $self->app->config->{'Plugin::Authentication'} || {};

        $self->app->ensure_class_loaded('Ark::Plugin::Authentication::Backend');
        my $class = $self->app->class_wrapper(
            name => 'Auth',
            base => 'Ark::Plugin::Authentication::Backend',
        );

        $class->new(
            app => $self->app,
            %$conf,
        );
    },
    handles => [qw/user authenticate logout/],
);

1;
