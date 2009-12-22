package Ark::Plugin::Authentication::Credential::Twitter;
use Ark::Plugin 'Auth';
use Carp;

has twitter_user_field => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->class_config->{user_field} || 'user_id';
    },
);

has twitter_consumer_key => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->class_config->{consumer_key};
    },
);

has twitter_consumer_secret => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->class_config->{consumer_secret};
    },
);

sub authenticate_twitter {
    my ($self, %param) = @_;
    my $c = $self->context;

    $self->ensure_class_loaded('Net::Twitter');
    my $nt = Net::Twitter->new(
        traits => [qw/API::REST OAuth/],
        consumer_key    => $self->twitter_consumer_key,
        consumer_secret => $self->twitter_consumer_secret,
    );
    
    my $verifier = $c->req->param('oauth_verifier');
    if ($verifier) {
        my $session = $c->session->get('_twitter_oauth')
            or return;

        $nt->request_token($session->{token});
        $nt->request_token_secret($session->{token_secret});

        my ($access_token, $access_token_secret, $user_id, $screen_name)
            = $nt->request_access_token(verifier => $verifier)
                or return;

        my $user = {
            access_token        => $access_token,
            access_token_secret => $access_token_secret,
            user_id             => $user_id,
            screen_name         => $screen_name,
        };

        my $user_obj = $self->find_user(
            $user->{ $self->twitter_user_field }, $user,
        ) or return;

        $self->persist_user($user_obj);
        return $user_obj;
    }
    else {
        my $url = $nt->get_authorization_url(%param);

        $c->session->set( _twitter_oauth => {
            token        => $nt->request_token,
            token_secret => $nt->request_token_secret,
        });

        $c->redirect_and_detach($url);
    }
};

1;
