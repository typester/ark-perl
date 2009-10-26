package Ark::Command::Newapp;
use Any::Moose;

extends 'Ark::Command::Plugin';

with 'Ark::Command::Interface::ModuleSetup';

sub search_app {}

__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

Ark::Command::Newapp;

=head1 SYNOPSIS

ark.pl newapp [app_name]

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=cut
