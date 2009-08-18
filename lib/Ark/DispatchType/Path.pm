package Ark::DispatchType::Path;
use Mouse;

use URI;

has name => (
    is      => 'rw',
    isa     => 'Str',
    default => 'Path',
);

has paths => (
    is      => 'rw',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { {} },
);

has list => (
    is      => 'rw',
    isa     => 'Text::SimpleTable | Undef',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return unless $self->used;

        eval "require Text::SimpleTable"; die $@ if $@;
        my $paths = Text::SimpleTable->new( [ 35, 'Path' ], [ 36, 'Private' ] );
        foreach my $path ( sort keys %{ $self->paths } ) {
            my $display_path = $path eq '/' ? $path : "/$path";
            foreach my $action ( @{ $self->{paths}->{$path} } ) {
                $paths->row( $display_path, '/' . $action->reverse );
            }
        }
        $paths;
    },
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

    my $actions = $self->paths->{$path} ||= [];
    my $args    = $action->args;

    if (defined $args) {
        my $p;
        for (my $i = 0; $i <= $#$actions; $i++) {
            last unless defined $actions->[$i]->args;
            $p = $i if $actions->[$i]->args >= $args;
        }

        unless ($p) {
            unshift @$actions, $action;
        }
        else {
            @$actions = @$actions[0..$p-1], $action, @$actions[$p..$#$actions];
        }
    }
    else {
        push @$actions, $action;
    }
}

sub used {
    my $self = shift;
    scalar( keys %{$self->paths} );
}

1;
