package Ark::Command;
use Mouse;

use Pod::Usage;
use Getopt::Long qw/GetOptionsFromArray/;

no Mouse;

sub run {
    my $self = shift;

    # parse command line
    my ($command, @global_args, @command_args);
    for my $arg (@ARGV) {
        if ($command) {
            push @command_args, $arg;
        }
        else {
            if ($arg =~ /^-/) {
                push @global_args, $arg;
            }
            else {
                $command = $arg;
            }
        }
    }

    GetOptionsFromArray(\@global_args, \my %option, qw/help/);
    $self->show_usage(0) if $option{help};

    # find command
    $self->show_usage unless $command;
    my $module = 'Ark::Command::' . camelize($command);
    eval "use $module";
    if ($@ or !$module->meta->does_role('Ark::Command::Interface')) {
        $self->show_usage(2, "no such command: $command")
    };

    $module->new->run(@command_args);
}

sub camelize {
    my $s = shift;
    join('', map{ ucfirst $_ } split(/(?<=[A-Za-z])_(?=[A-Za-z])|\b/, $s));
}

sub show_usage {
    my ($self, $exitval, $message) = @_;

    my $caller  = caller(0);
    (my $module = $caller) =~ s!::!/!g;
    my $file = $INC{"${module}.pm"};

    pod2usage( -exitval => $exitval, -input => $file, -message => $message );
}

1;

__END__

=head1 SYNOPSIS

 ark.pl [command] [command_args...]
 
 Commands:
  newapp      - create new application
  controller  - create controller
  view        - create view
  model       - create model
 
 "ark.pl [command] --help" for command specific usage.

=cut
