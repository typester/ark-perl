package Ark::Plugin::Authentication::Backend;
use Ark 'Component';

has user => (
    is      => 'rw',
    isa     => 'Maybe[Ark::Plugin::Authentication::User]',
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
    $self->context->session->regenerate;
    $self->context->session->set( __user => $user->for_session );
}

sub restore_user {
    my $self = shift;

    my $user = $self->context->session->get('__user') or return;

    return unless ref $user eq 'HASH';
    return unless $user->{hash} && $user->{store};

    $self->from_session($user);
}

sub logout {
    my $self = shift;
    $self->context->session->remove( '__user' );
}

# Credential
sub authenticate { }

# Store
sub find_user { }
sub from_session { }

1;
