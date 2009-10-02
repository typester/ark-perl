package Ark::Request;
use Mouse;

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
        $class->meta->add_method( base => sub {
            my $self = shift;
            my $vpath = $self->path;
            my $path  = $self->uri->path;

            (my $base = $path) =~ s/$vpath$/\//;

            return $base;
        });

        return  $class->new( $req->env );
    }
    else {
        $class->meta->superclasses('HTTP::Engine::Request');
        return $class->new(%$req);
    }

}

1;

