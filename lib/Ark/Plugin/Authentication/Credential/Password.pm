package Ark::Plugin::Authentication::Credential::Password;
use Ark::Plugin 'Auth';

has cred_password_user_field => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->class_config->{user_field} || 'username';
    },
);

has cred_password_password_field => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->class_config->{password_field} || 'password';
    },
);

has cred_password_password_type => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->class_config->{password_type} || 'clear';
    },
);

has cred_password_password_digest_model => (
    is      => 'rw',
    isa     => 'Object',
    lazy    => 1,
    default => sub {
        my $self  = shift;
        my $model = $self->app->model($self->class_config->{digest_model})
            || $self->app->model('Digest');
    },
);

has cred_password_password_pre_salt => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->class_config->{password_pre_salt} || '';
    },
);

has cred_password_password_post_salt => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->class_config->{password_post_salt} || '';
    },
);

around authenticate => sub {
    my $prev = shift->(@_);
    return $prev if $prev;

    my ($self, $info) = @_;

    my $id = $info->{ $self->cred_password_user_field };
    if (my $user = $self->find_user($id, $info)) {
        if ($self->method('check_password')->($info, $user)) {
            $self->persist_user($user);
            return $user;
        }
    }

    return;
};

sub check_password {
    my ($self, $info, $user) = @_;

    my $password          = $info->{ $self->cred_password_password_field };
    my $password_expected = $user->hash->{ $self->cred_password_password_field };

    if ($self->cred_password_password_type eq 'clear') {
        return $password eq $password_expected;
    }
    elsif ($self->cred_password_password_type eq 'hashed') {
        my $digest = $self->cred_password_password_digest_model;
        $digest->reset;
        $digest->add( $self->cred_password_password_pre_salt );
        $digest->add( $password );
        $digest->add( $self->cred_password_password_post_salt );

        my $hashed = $digest->hexdigest;

        $digest->reset;

        return $hashed eq $password_expected;
    }
    else {
        die qq/Unknown password type "$self->{password_type}"/;
    }
}

1;
