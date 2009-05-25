package Ark::Command::Newapp;
use Mouse;

extends 'Ark::Command::Plugin';

with 'Ark::Command::Interface::ModuleSetup';

1;

__END__

=head1 NAME

Ark::Command::Newapp;

=head1 SYNOPSIS

ark.pl newapp [app_name]

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=cut
