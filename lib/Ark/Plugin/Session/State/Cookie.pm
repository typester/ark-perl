package Ark::Plugin::Session::State::Cookie;
use Ark::Plugin 'Session';

has cookie_name => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->class_config->{cookie_name} || lc(ref $self->app) . '_session';
    },
);

has cookie_domain => (
    is      => 'rw',
    isa     => 'Maybe[Str]',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->class_config->{cookie_domain};
    },
);

has cookie_path => (
    is      => 'rw',
    isa     => 'Maybe[Str]',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->class_config->{cookie_path};
    },
);


has cookie_expires => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        exists $self->class_config->{cookie_expires}
             ? $self->class_config->{cookie_expires}
      : exists $self->app->config->{'Plugin::Session'}->{expires}
             ? $self->app->config->{'Plugin::Session'}->{expires}
      :        '+1d';    # 1day
    },
);

has cookie_secure => (
    is      => 'rw',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->class_config->{cookie_secure} || 0;
    },
);

has cookie_remove_marker => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

has update_cookie => (
    is      => 'rw',
    isa     => 'HashRef',
);

around 'get_session_id' => sub {
    my $next = shift;
    my $prev = $next->(@_);
    return $prev if $prev;

    my ($self)  = @_;
    my $request = $self->context->request;

    unless ($self->cookie_remove_marker) {
        if ( my $cookie = $request->cookies->{ $self->cookie_name } ) {
            my $sid = ref $cookie ? $cookie->value : $cookie;
            $self->log( debug => q[Found sessionid "%s" in cookie], $sid );
            return $sid if $sid;
        }
    }

    return;
};

around 'set_session_id' => sub {
    my $next = shift;
    my ($self, $sid) = @_;

    $self->update_cookie( $self->make_cookie($sid) );

    $next->(@_);
};

around 'remove_session_id' => sub {
    my $next = shift;
    my ($self, $sid) = @_;

    $self->session_id(undef);
    $self->cookie_remove_marker(1);
    $self->update_cookie(
        $self->make_cookie( $sid, { expires => 0 } )
    );

    $next->(@_);
};

around 'finalize_session' => sub {
    my $next   = shift;
    my ($self, $res) = @_;

    my $cookie = $self->update_cookie;
    my $sid    = $self->get_session_id;

    if (!$cookie && $sid) {
        $cookie = $self->make_cookie($sid);
    }

    if ($cookie) {
        $res->cookies->{ $self->cookie_name } = $cookie;
    }

    $next->(@_);
};

sub make_cookie {
    my ($self, $sid, $attrs) = @_;

    my $cookie = {
        value   => $sid,
        expires => $self->cookie_expires,
        secure  => $self->cookie_secure,
        $self->cookie_domain ? (domain => $self->cookie_domain) : (),
        $self->cookie_path   ? (path   => $self->cookie_path) : (),
        %{ $attrs || {} },
    };
}

1;
