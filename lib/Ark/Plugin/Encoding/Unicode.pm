package Ark::Plugin::Encoding::Unicode;
use Ark::Plugin;
use Scalar::Util 'blessed';

use Encode;

sub prepare_encoding {
    my $self = shift;
    my $req  = $self->request;

    my $encode = sub {
        my ($p) = @_;

        my $decoded = Hash::MultiValue->new;

        $p->each(sub {
            $decoded->add( $_[0], decode_utf8($_[1]) );
        });

        $decoded;
    };

    $req->env->{'plack.request.query'} = $encode->($req->query_parameters);
    $req->env->{'plack.request.body'}  = $encode->($req->body_parameters);

    if ($req->env->{'plack.request.merged'}) {
        $req->env->{'plack.request.merged'} = $encode->($req->env->{'plack.request.merged'});
    }
};

sub finalize_encoding {
    my $self = shift;

    my $res = $self->response;
    $res->body(encode_utf8 $res->body ) if !$res->binary and $res->has_body;
};

1;
