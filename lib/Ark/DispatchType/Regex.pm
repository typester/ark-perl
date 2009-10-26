package Ark::DispatchType::Regex;
use Any::Moose;

extends 'Ark::DispatchType::Path';

has name => (
    is      => 'rw',
    isa     => 'Str',
    default => 'Regex',
);

has compiled => (
    is      => 'rw',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub { [] },
);

has list => (
    is      => 'rw',
    isa     => 'Maybe[Object]',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return unless $self->used;

        eval "require Text::SimpleTable"; die if $@;
        my $re = Text::SimpleTable->new( [ 35, 'Regex' ], [ 36, 'Private' ] );
        for my $regex (@{ $self->compiled }) {
            $re->row( $regex->{path}, "/" . $regex->{action}->reverse );
        }
        $re;
    },
);

no Any::Moose;

sub register {
    my ($self, $action) = @_;

    my @register = @{ $action->attributes->{Regex} || [] }
        or return;

    for my $r (@register) {
        $self->register_path( $r, $action );
        $self->register_regex( $r, $action );
    }

    1;
}

sub register_regex {
    my ($self, $re, $action) = @_;

    push @{ $self->compiled }, {
        re     => qr/$re/,
        action => $action,
        path   => $re,
    };
}

sub match {
    my ($self, $req, $path) = @_;

    return if $self->SUPER::match( $req, $path );

    for my $compiled (@{ $self->compiled }) {
        if (my @captures = $path =~ $compiled->{re}) {
            next unless $compiled->{action}->match($req);
            $req->action($compiled->{action});
            $req->match($path);
            $req->captures( \@captures );
            return 1;
        }
    }

    return;
}

sub used {
    my $self = shift;
    scalar @{ $self->compiled };
}

__PACKAGE__->meta->make_immutable;

