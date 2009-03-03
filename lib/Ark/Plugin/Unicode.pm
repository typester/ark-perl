package Ark::Plugin::Unicode;
use Ark::Plugin;

after 'prepare' => sub {
    my $self = shift;
    my $req  = $self->request;

    for my $value (values %{ $req->parameters }) {
        next if ref $value and ref $value ne 'ARRAY';
        utf8::decode($_) for ref $value ? @$value : ($value);
    }
};

after 'finalize' => sub {
    my $self = shift;

    utf8::encode( $self->response->{body} ) if defined $self->response->{body};
};

1;

