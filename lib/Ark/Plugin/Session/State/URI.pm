package Ark::Plugin::Session::State::URI;
use Ark::Plugin 'Session';

has uri_query => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->class_config->{query} || 'sid';
    },
);

has uri_verify_ua => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->class_config->{verify_ua} || 1;
    },
);

has uri_rewrite_mobile_only => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->class_config->{mobile_only} || 1;
    },
);

has uri_remove_marker => (
    is      => 'rw',
    default => 0,
);

has uri_handled => (
    is      => 'rw',
    default => 0,
);

has uri_session_id => (
    is      => 'rw',
    default => '',
);

has uri_session_disabled => (
    is      => 'rw',
    default => 0,
);

around get_session_id => sub {
    my $next = shift;
    my $prev = $next->(@_);
    return $prev if $prev;

    my ($self) = @_;
    my $req    = $self->context->request;

    return if $self->uri_session_disabled;
    if ($self->uri_rewrite_mobile_only) {
        my $agent = $self->context->can('mobile_agent')
            or $self->log( debug => q[Require MobileAgent plugin for this feature] );
        if ($agent && $self->context->mobile_agent->is_non_mobile) {
            $self->log(
                warn => q[Disabled uri_session because the user agent is detected as non mobile]
            );
            $self->uri_session_disabled(1);
            return;
        }
    }

    unless ($self->uri_remove_marker) {
        if (my $sid = $req->param( $self->uri_query )) {
            $self->log( debug => q[Found sessionid "%s" in uri], $sid );

            if ($self->uri_verify_ua) {
                my $session = $self->get_session_data($sid);
                if ($session) {
                    if (($session->{__ua} || '') ne $req->user_agent) {
                        $self->log( debug => q[But user_agent is mismatch, ignore this sessionid] );
                        return;
                    }
                }
            }

            return $self->uri_session_id($sid);
        }
    }

    return;
};

around set_session_id => sub {
    my $next = shift;
    my ($self, $sid) = @_;

    unless ($self->uri_session_disabled) {
        $self->uri_session_id($sid);
    }

    $next->(@_);
};

around remove_session_id => sub {
    my $next = shift;
    my ($self, $sid) = @_;

    unless ($self->uri_session_disabled) {
        $self->session_id(undef);
        $self->uri_remove_marker(1);
        $self->uri_session_id(undef);
    }

    $next->(@_);
};

around finalize_session => sub {
    my $next = shift;
    my ($self, $res) = @_;

    unless ($self->uri_session_disabled) {
        if ($self->uri_verify_ua) {
            # store ua
            if ($self->session_updated) {
                $self->set( __ua => $self->context->request->user_agent );
            }
        }
    }

    $next->(@_);
};

sub BUILD {
    my ($self) = @_;
    
    my $context_class = $self->app->context_class;
    my $role = 'Ark::Plugin::Session::State::URI::ExtendContext';

    return if $context_class->meta->does_role($role);

    $self->ensure_class_loaded($role);
    $role->meta->apply( $context_class->meta );
}

1;
