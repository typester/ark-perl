package Ark::Plugin::Encoding::Unicode;
use Ark::Plugin;
use Scalar::Util 'blessed';

sub prepare_encoding {
    my $self = shift;
    my $req  = $self->request;

    my $encode = sub {
        my ($p, $skip) = @_;

        if (blessed $p and $p->isa('Hash::MultiValue')) {
            return if $skip;
            $p->each(sub {
                utf8::decode($_[1]);
            });
        }
        else {
            # backward compat
            for my $value (values %$p) {
                next if ref $value and ref $value ne 'ARRAY';
                utf8::decode($_) for ref $value ? @$value : ($value);
            }
        }
    };

    $encode->($req->query_parameters);
    $encode->($req->body_parameters);
    $encode->($req->parameters, 1)
};

sub finalize_encoding {
    my $self = shift;

    utf8::encode( $self->response->{body} ) if defined $self->response->{body};
};

1;
