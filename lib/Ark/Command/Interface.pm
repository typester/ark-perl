package Ark::Command::Interface;
use Mouse::Role;

use Pod::Usage;
use Getopt::Long qw/GetOptionsFromArray/;

requires 'run', 'option_list';

has options => (
    is      => 'rw',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { {} },
);

around run => sub {
    my $next = shift;
    my ($self, @args) = @_;

    GetOptionsFromArray(\@args, $self->options, $self->option_list);
    $next->($self, @args);
};

no Mouse::Role;

sub show_usage {
    my ($self, $exitval, $message) = @_;

    my $caller  = caller(0);
    (my $module = $caller) =~ s!::!/!g;
    my $file = $INC{"${module}.pm"};

    pod2usage( -exitval => $exitval, -input => $file, -message => $message );
}

1;

