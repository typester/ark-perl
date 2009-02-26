package Ark::Context;
use Mouse;
use Mouse::Util::TypeConstraints;

use Ark::Request;
use HTTP::Engine::Response;

subtype 'Ark::Request'
    => as 'Object'
    => where { $_->isa('Ark::Request') };

coerce 'Ark::Request'
    => from 'Object'
    => via {
        $_->isa('Ark::Request') ? $_ : Ark::Request->new(%$_);
    };

has request => (
    is       => 'rw',
    isa      => 'Ark::Request',
    required => 1,
    coerce   => 1,
);

has response => (
    is      => 'rw',
    isa     => 'HTTP::Engine::Response',
    lazy    => 1,
    default => sub {
        HTTP::Engine::Response->new;
    },
);

has stash => (
    is      => 'rw',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { {} },
);

{   # alias
    no warnings 'once';
    *req = \&request;
    *res = \&response;
}

1;

