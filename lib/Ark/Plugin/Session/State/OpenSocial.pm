package Ark::Plugin::Session::State::OpenSocial;
use Ark::Plugin 'Session';

around get_session_id => sub {
    my $prev = shift->(@_);
    return $prev if $prev;

    my ($self)  = @_;
    my $request = $self->context->request;

    if (my $id = $request->param('opensocial_owner_id')) {
        $self->log( debug => q[Found opensocial_owner_id "%s"], $id );
        return $id;
    }

    return;
};

around initialize_session_data => sub {
    my $next = shift;
    my ($self) = @_;
    my $request = $self->context->request;

    if (my $id = $request->param('opensocial_owner_id')) {
        $self->set_session_id( $id );
        $self->session_data({});
    }
    else {
        $next->(@_);
    }
};

1;
