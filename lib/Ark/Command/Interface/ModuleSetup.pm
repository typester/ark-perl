package Ark::Command::Interface::ModuleSetup;
use Mouse::Role;

with 'Ark::Command::Interface';

use Path::Class qw/dir/;
use File::HomeDir;
use Module::Setup;

has module_setup_options => (
    is      => 'rw',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my ($module) = ref($self) =~ /^Ark::Command::(.+)/;

        return {
            flavor_class     => "+Ark::Command::Flavor::${module}",
            module_setup_dir => dir(File::HomeDir->my_home)
                                    ->subdir('.arkhelper', lc $module),
            $self->options->{init} ? (init => 1) : (),
        };
    },
);

no Mouse::Role;

sub option_list {
    qw/flavor=s init app=s/
}

sub run {
    my ($self, @args) = @_;

    local $Module::Setup::HAS_TERM = 1;

    if ($self->module_setup_options->{init}) {
        Module::Setup->new(
            options => $self->module_setup_options,
            argv    => [$self->options->{flavor} || ()],
        )->run;
    }
    else {
        my $module = shift @args
            or $self->show_usage(-1, "Error: required target name\n", ref($self));

        $self->module_setup_options->{ark_script}     = $self,
        $self->module_setup_options->{ark_class}      = $module;
        $self->module_setup_options->{ark_base_class} = shift @args;
        $self->module_setup_options->{ark_app}        = $self->options->{app}
                                                          || $self->search_app;
        my $setup = Module::Setup->new(
            options => $self->module_setup_options,
            argv    => [$module, $self->options->{flavor}],
        );
        $setup->run;
    }
}

1;
