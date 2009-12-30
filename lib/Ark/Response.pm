package Ark::Response;
use Any::Moose;

use Carp ();
use Scalar::Util ();
use CGI::Simple::Cookie ();
use HTTP::Headers;

has status => (
    is      => 'rw',
    isa     => 'Int',
    default => 200,
);

has headers => (
    is      => 'rw',
    isa     => 'HTTP::Headers',
    lazy    => 1,
    default => sub {
        HTTP::Headers->new;
    },
);

has body => (
    is        => 'rw',
    predicate => 'has_body',
);

has cookies => (
    is      => 'rw',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { {} },
);

has streaming => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

has streaming_writer => (
    is  => 'rw',
    isa => 'CodeRef',
);

no Any::Moose;

sub code { shift->status(@_) }
sub content { shift->body(@_) }

sub header { shift->headers->header(@_) }

sub content_length {
    shift->headers->content_length(@_);
}

sub content_type {
    shift->headers->content_type(@_);
}

sub content_encoding {
    shift->headers->content_encoding(@_);
}

sub location {
    shift->headers->header('Location' => @_);
}

sub finalize {
    my $self = shift;
    die "missing status" unless $self->status();

    $self->_finalize_cookies();

    my $response = [
        $self->status,
        +[
            map {
                my $k = $_;
                map { ( $k => $_ ) } $self->headers->header($_);
            } $self->headers->header_field_names
        ],
    ];

    if ($self->streaming) {
        my $res = sub {
            my $respond = shift;
            my $writer  = $respond->($response);
            $self->streaming_writer($writer);
        };
        Scalar::Util::weaken($self);

        return $res;
    }
    else {
        push @$response, $self->_body;
        return $response;
    }
}

sub _body {
    my $self = shift;
    my $body = $self->body;
       $body = [] unless defined $body;
    if (!ref $body or Scalar::Util::blessed($body) && overload::Method($body, q(""))) {
        return [ $body ];
    } else {
        return $body;
    }
}

sub _finalize_cookies {
    my ( $self ) = @_;

    my $cookies = $self->cookies;
    my @keys    = keys %$cookies;
    if (@keys) {
        for my $name (@keys) {
            my $val    = $cookies->{$name};
            my $cookie = (
                Scalar::Util::blessed($val)
                ? $val
                : CGI::Simple::Cookie->new(
                    -name    => $name,
                    -value   => $val->{value},
                    -expires => $val->{expires},
                    -domain  => $val->{domain},
                    -path    => $val->{path},
                    -secure  => ( $val->{secure} || 0 )
                )
            );

            $self->headers->push_header( 'Set-Cookie' => $cookie->as_string );
        }
    }
}

__PACKAGE__->meta->make_immutable;
