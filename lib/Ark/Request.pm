package Ark::Request;
use Any::Moose;

BEGIN {
    if (any_moose eq 'Mouse') {
        eval q[use MouseX::Foreign; 1]
            or die $@;        
    }
    else {
        eval q[use MooseX::NonMoose; 1]
            or die $@;
    }
}

extends 'Plack::Request';

use URI::WithBase;
use Path::AttrRouter::Match;

has match => (
    is      => 'rw',
    isa     => 'Path::AttrRouter::Match',
    handles => [qw/action args captures/],
);

{
    no warnings 'once';
    *arguments = \&args;
}

no Any::Moose;

sub wrap {
    my ($class, $req) = @_;

    return $class->new( $req->env );
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

