package Ark::Plugin::ReproxyCallback::OpenSocial;
use Ark::Plugin;

use HTTP::Request;

requires 'reproxy';

has reproxy_callback_opensocial_oauth_consumer_model => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my ($self) = @_;
        $self->class_config->{oauth_consumer_model} || 'oauth_consumer';
    },
);

has reproxy_callback_opensocial_api_endpoint => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my ($self) = @_;
        $self->class_config->{api_endpoint} || 'http://api.mixi-platform.com/os/0.8';
    },
);

around reproxy => sub {
    my $next = shift;
    my $c    = shift;
    my $args = @_ > 1 ? {@_} : $_[0];

    if (my $req = delete $args->{request}) {
        my $consumer =
            $c->model( $c->reproxy_callback_opensocial_oauth_consumer_model );
        my $oauth_req = $consumer->gen_oauth_request(
            method  => $req->method,
            url     => $req->uri->scheme . '://'
                           . $req->uri->authority . $req->uri->path,
            headers => [map { $_ => $req->header(@_) } $req->header_field_names],
            params  => {
                xoauth_requestor_id => $c->req->param('opensocial_owner_id') || '',
                $req->uri->query_form,
            },
        );

        $args->{request} = $oauth_req;
    }

    $next->($c, $args);
};

sub reproxy_opensocial {
    my $c      = shift;
    my $method = shift;
    my $path   = shift;
    my $args   = @_ > 1 ? {@_} : $_[0];

    my $cb     = delete $args->{callback};
    my $params = delete $args->{params};

    my $uri = URI->new( $c->reproxy_callback_opensocial_api_endpoint . $path );
    $uri->query_form(%$params) if $params;

    $c->reproxy(
        request  => HTTP::Request->new( $method => $uri ),
        callback => $cb,
    );
}

sub reproxy_people {
    my $cb = pop @_;
    my ($c, $guid, $target, $params) = @_;

    my $uri = URI->new( $c->reproxy_callback_opensocial_api_endpoint );
    $uri->path( $uri->path . "/people/${guid}/${target}" );
    $uri->query_form(%$params) if $params;

    $c->reproxy(
        request  => HTTP::Request->new( GET => $uri ),
        callback => $cb,
    );
}

1;


