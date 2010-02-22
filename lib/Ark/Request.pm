package Ark::Request;
use Any::Moose;

use URI::WithBase;

has action => (
    is  => 'rw',
    isa => 'Ark::Action',
);

has match => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub { '' },
);

has arguments => (
    is      => 'rw',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub { [] },
);

has captures => (
    is      => 'rw',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub { [] },
);

{
    no warnings 'once';
    *args = \&arguments;
}

no Any::Moose;

sub wrap {
    my ($class, $req) = @_;

    if ($req->isa('Plack::Request')) {
        $class->meta->superclasses('Plack::Request');
        return  $class->new( $req->env );
    }
    else {
        die "Request class should be inheritance Plack::Request";
    }
}

sub uri_with {
    my ($self, $args) = @_;

    my $uri = $self->uri->clone;

    my %params = $uri->query_form;
    while (my ($k, $v) = each %$args) {
        $params{$k} = $v;
    }
    $uri->query_form(%params);

    return $uri;
}

1;

