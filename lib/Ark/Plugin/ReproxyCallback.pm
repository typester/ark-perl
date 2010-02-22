package Ark::Plugin::ReproxyCallback;
use Ark::Plugin;

use URI;

sub reproxy {
    my $c = shift;
    my $args = @_ > 1 ? {@_} : $_[0];
    my $res  = $c->response;

    if (my $req = $args->{request}) {
        $res->header('X-Reproxy-Method' => $req->method);
        $res->header('X-Reproxy-URL'    => $req->uri);
        for my $h ($req->headers->header_field_names) {
            $res->header('X-Reproxy-Header-' . $h => $req->header($h));
        }
    }

    if (my $callback = $args->{callback}) {
        $res->header('X-Reproxy-Callback' => $callback);
    }

    $res->body('') unless $res->has_body;
}

after prepare_action => sub {
    my $c = shift;

    if (my $uri = $c->request->header('X-Reproxy-Original-URL')) {
        $c->request->header('X-Reproxy-Callback-URL' => $c->request->uri );
        $c->request->uri(URI->new($uri));
    }
};

1;

