package Ark::Logger;
use Mouse;
use utf8;

has log_level => (
    is      => 'rw',
    isa     => 'Str',
    default => $ENV{ARK_DEBUG} ? 'debug' : 'error',
);

has log_levels => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub {
        {   debug => 4,
            info  => 3,
            warn  => 2,
            error => 1,
            fatal => 0,
        };
    },
);

no Mouse;

{
    no strict 'refs';
    my $pkg = __PACKAGE__;
    for my $level (qw/debug info warn error fatal/) {
        *{"${pkg}::${level}"} = sub {
            my ($self, $msg, @args) = @_;
            print STDERR sprintf("[%s] $msg\n", $level, @args);
        };
    }
}

sub log {
    my ($self, $type, $msg, @args) = @_;

    return if !$self->log_levels->{$type}
        or $self->log_levels->{$type} > $self->log_levels->{ $self->log_level };

    print STDERR sprintf("[%s] ${msg}\n", $type, @args);
}

__PACKAGE__->meta->make_immutable;

