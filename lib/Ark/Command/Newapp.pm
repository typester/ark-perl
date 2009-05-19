package Ark::Command::Newapp;
use Mouse;

with 'Ark::Command::Interface';

use Module::Setup;
use Path::Class qw/dir/;

sub option_list {
    qw/flavor=s init/;
}

sub run {
    my ($self, @args) = @_;
    local $Module::Setup::HAS_TERM = 1;

    my $ms_options = {
        flavor_class     => '+Ark::Command::Flavor::Newapp',
        module_setup_dir => dir(File::HomeDir->my_home)
                                ->subdir('.arkhelper', 'newapp'),
        $self->options->{init} ? (init => 1) : (),
    };

    if ($ms_options->{init}) {
        Module::Setup->new(
            options => $ms_options,
            argv    => [$self->options->{flavor} || ()],
        )->run;
    }
    else {
        my $app_name = shift @args or $self->show_usage( -1, 'required app_name' );

        my $ms = Module::Setup->new(
            options => $ms_options,
            argv    => [$app_name, $self->options->{flavor}],
        );
        $ms->run;
    }
}

1;

__END__

=head1 NAME

Ark::Command::Newapp;

=head1 SYNOPSIS

ark.pl newapp [app_name]

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=cut
