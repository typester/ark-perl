package Ark::Plugin::Authentication::Backend;
use Ark 'Component';

has user => (
    is      => 'rw',
    isa     => 'Ark::Plugin::Authentication::User',
    lazy    => 1,
    builder => 'restore_user',
);

has realms => (
    is      => 'rw',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub {
        my $self = shift;

        my $conf = $self->app->config->{'Plugin::Authentication'}
    },
);

sub persist_user {
    my ($self, $user) = @_;
    $self->context->session->set( __user => $self->for_session($user) );
}

# Credential
sub authenticate { }

# Store
sub find_user { }
sub restore_user { }
sub for_session { }

1;
