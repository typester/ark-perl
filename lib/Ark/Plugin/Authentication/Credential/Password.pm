package Ark::Plugin::Authentication::Credential::Password;
use Ark::Plugin 'Auth';

has password_field => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->class_config->{password_field} || 'password';
    },
);

has password_type => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->class_config->{password_type} || 'clear';
    },
);

has password_digest_model => (
    is      => 'rw',
    isa     => 'Object',
    lazy    => 1,
    default => sub {
        my $self  = shift;
        my $model = $self->app->model($self->class_config->{digest_model})
            || $self->app->model('Digest');
    },
);

has password_pre_salt => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->class_config->{password_pre_salt} || '';
    },
);

has password_post_salt => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->class_config->{password_post_salt} || '';
    },
);

around authenticate => sub {
    my $next = shift;
    my ($self, $info) = @_;

    if (my $user = $self->find_user($info)) {
        if ($self->method('check_password')->($info, $user)) {
            $self->persist_user($user);
            return $user;
        }
    }

    $next->(@_);
};

sub check_password {
    my ($self, $info, $user) = @_;

    my $password          = $info->{ $self->password_field };
    my $password_expected = $user->hash->{ $self->password_field };

    if ($self->password_type eq 'clear') {
        return $password eq $password_expected;
    }
    elsif ($self->password_type eq 'hashed') {
        my $digest = $self->password_digest_model;
        $digest->reset;
        $digest->add( $self->password_pre_salt );
        $digest->add( $password );
        $digest->add( $self->password_post_salt );

        my $hashed = $digest->hexdigest;

        $digest->reset;

        return $hashed eq $password_expected;
    }
    else {
        die qq/Unknown password type "$self->{password_type}"/;
    }
}

1;
