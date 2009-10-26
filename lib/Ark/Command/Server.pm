package Ark::Command::Server;
use Any::Moose;

with 'Ark::Command::Interface';

use Cwd qw/cwd/;
use Path::Class qw/dir/;

no Any::Moose;

sub option_list {
    qw/help debug port=i address=s/
}

sub run {
    my ($self, @args) = @_;
    $self->show_usage(0);
}

__PACKAGE__->meta->make_immutable;

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
