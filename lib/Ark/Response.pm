package Ark::Response;
use Any::Moose;

use Carp ();
use Scalar::Util ();
use CGI::Simple::Cookie ();
use HTTP::Headers;
use Plack::Util;

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

has binary => (
    is      => 'rw',
    default => 0,
);

has cookies => (
    is      => 'rw',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { {} },
);

has streaming => (
    is        => 'rw',
    isa       => 'CodeRef',
    predicate => 'is_streaming',
);

has deferred => (
    is        => 'rw',
    isa       => 'CodeRef',
    predicate => 'is_deferred',
);

has deferred_response => (
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

    if ($self->is_deferred) {
        if (my $cb = $self->deferred_response) {
            my $body = $self->_body;

            my $response = [
                $self->status,
                +[
                    map {
                        my $k = $_;
                        map { ( $k => $_ ) } $self->headers->header($_);
                    } $self->headers->header_field_names
                ],
                $body,
            ];

            $cb->($response);
        }
        else {
            my $r = sub {
                my $respond = shift;
                $self->deferred_response($respond);
                $self->deferred->($respond);
            };
            Scalar::Util::weaken($self);
            return $r;
        }
    }
    else {
        my $response = [
            $self->status,
            +[
                map {
                    my $k = $_;
                    map { ( $k => $_ ) } $self->headers->header($_);
                } $self->headers->header_field_names
            ],
        ];

        if ($self->is_streaming) {
            return sub {
                my $respond = shift;
                my $writer  = $respond->($response);
                $self->streaming->($writer);
            };
        }
        else {
            push @$response, $self->_body;
            return $response;
        }
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
                : do {
                    my %args = (
                        -name    => $name,
                        -value   => $val->{value},
                        -domain  => $val->{domain},
                        -path    => $val->{path},
                        -secure  => ( $val->{secure} || 0 )
                    );
                    $args{"-expires"} = $val->{expires} if defined $val->{expires};
                    CGI::Simple::Cookie->new(%args);
                }
            );

            $self->headers->push_header( 'Set-Cookie' => $cookie->as_string );
        }
    }
}

__PACKAGE__->meta->make_immutable;
