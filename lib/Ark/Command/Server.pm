package Ark::Command::Server;
use Mouse;

with 'Ark::Command::Interface';

use Cwd qw/cwd/;
use Path::Class qw/dir/;

no Mouse;

sub option_list {
    qw/help debug port=i address=s/
}

sub run {
    my ($self, @args) = @_;
    $self->show_usage(0);
}

1;

__END__

=head1 NAME

Ark::Command::Server - ark.pl subcommand 'server'

=head1 SYNOPSIS

This command has been DEPRECATED!

Use "plackup" command instead of this.
See "perldoc plackup" for more info.

And though current version of Ark generate default app.psgi when "ark.pl newapp",
if your application generated before it, you should make own app.psgi manually.

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=cut
