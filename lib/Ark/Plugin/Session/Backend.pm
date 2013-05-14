package Ark::Plugin::Session::Backend;
use Ark 'Component';

has session_id => (
    is      => 'rw',
    isa     => 'Maybe[Str]',
    lazy    => 1,
    builder => 'get_session_id',
);

has session_data => (
    is      => 'rw',
    isa     => 'Maybe[HashRef]',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return unless $self->session_id;
        $self->get_session_data( $self->session_id );
    },
);

has session_updated => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

has uuid_model => (
    is  => 'rw',
    isa => 'Str',
);

has digest_model => (
    is  => 'rw',
    isa => 'Str',
);

has expire => (
    is      => "rw",
    isa     => "Int",
    default => 0,
);

has finalized => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

after $_ => sub { shift->session_updated(1); }
    for qw/get set remove/;

before $_ => sub {
    die "session is already finalized. can't call set or remove method" if shift->finalized;
} for qw/set remove/;

no Ark;

sub get {
    my ($self, $key) = @_;
    my $data = $self->session_data or return;
    $data->{ $key };
}

sub set {
    my ($self, $key, $value) = @_;
    $self->initialize_session_data unless $self->session_data;
    $self->session_data->{ $key } = $value;
}

sub remove {
    my ($self, $key) = @_;
    return unless $self->session_data;
    delete $self->session_data->{ $key };
}

sub regenerate {
    my ($self) = @_;

    # ignore if session does not exists
    return unless $self->session_id;

    my $session_data = $self->session_data;
    $self->remove_session_data($self->session_id);

    $self->initialize_session_data;
    $self->set_session_data($self->session_id => $session_data);
    $self->session_data($session_data);
}

sub initialize_session_data {
    my $self = shift;

    my $uuid   = $self->uuid_model && $self->app->model( $self->uuid_model );
    my $digest = $self->digest_model && $self->app->model( $self->digest_model );

    unless ($uuid) {
        $self->ensure_class_loaded('Data::UUID');
        $uuid = Data::UUID->new;
    }

    unless ($digest) {
        $self->ensure_class_loaded('Digest::SHA1');
        $digest = Digest::SHA1->new;
    }

    $digest->add( $uuid->create );

    $self->set_session_id( $digest->hexdigest );
    $self->session_data({});
}

# State
sub get_session_id { }

sub set_session_id {
    my ($self, $sid) = @_;
    $self->session_id($sid);
}

sub remove_session_id { }
# sub extend_session_id { }


# Store
sub get_session_data { }
sub set_session_data { }
sub remove_session_data { }

sub finalize_session {
    my ($self, $res) = @_;

    if ($self->session_updated and my $sid = $self->session_id) {
        $self->set_session_data( $sid, $self->session_data );
    }
    $self->finalized(1);
}

1;
