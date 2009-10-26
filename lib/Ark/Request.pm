package Ark::Request;
use Mouse;

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

no Mouse;

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

1;

