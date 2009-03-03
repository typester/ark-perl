package Ark::DispatchType::Path;
use Mouse;

use URI;

has paths => (
    is      => 'rw',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { {} },
);

no Mouse;

sub match {
    my ($self, $req, $path) = @_;

    $path = '/' if !defined $path || !length $path;

    for my $action (@{ $self->paths->{$path} || [] }) {
        next unless $action->match($req);
        $req->action($action);
        $req->match($path);
        return 1;
    }

    return;
}

sub register {
    my ($self, $action) = @_;

    my @register = @{ $action->attributes->{Path} || [] }
        or return;

    $self->register_path( $_, $action ) for @register;

    1;
}

sub register_path {
    my ($self, $path, $action) = @_;
    $path =~ s!^/!!;
    $path = '/' unless length $path;
    $path = URI->new($path)->canonical;

    unshift @{ $self->paths->{$path} ||= [] }, $action;
}

sub list {
    my $self = shift;

    return unless keys %{ $self->paths };

    eval "require Text::SimpleTable"; die $@ if $@;
    my $paths = Text::SimpleTable->new( [ 35, 'Path' ], [ 36, 'Private' ] );
    foreach my $path ( sort keys %{ $self->{paths} } ) {
        my $display_path = $path eq '/' ? $path : "/$path";
        foreach my $action ( @{ $self->{paths}->{$path} } ) {
            $paths->row( $display_path, '/' . $action->reverse );
        }
    }
    "Loaded Path actions:\n" . $paths->draw;
}

1;

