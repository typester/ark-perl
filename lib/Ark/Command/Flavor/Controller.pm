package Ark::Command::Flavor::Controller;
use strict;
use warnings;

use base qw/Ark::Command::Flavor::Newapp/;

sub setup_module_attribute {
    my $setup = shift;
    $setup->distribute->{dist_path} = Module::Setup::Path::Dir->new('.');
}

sub setup_template_vars {
    my ($setup, $vars) = @_;

    my $conf = $vars->{config};
    my $app  = $conf->{ark_app};
    my $ark  = $conf->{ark_script};

    $ark->show_usage(
        -1, "Error: can't detect ark application under this directory", ref($ark)
    ) unless $app;

    eval "use ${app}";
    die $@ if $@;

    $vars->{ark_app}        = $app;
    $vars->{ark_target}     = $vars->{config}{ark_class};
    $vars->{ark_base_class} = $vars->{config}{ark_base_class} || 'Controller';

    ($vars->{ark_app_path} = $vars->{ark_app}) =~ s!::!/!g;
    ($vars->{ark_target_path} = $vars->{ark_target}) =~ s!::!/!g;
}

1;

__DATA__

---
file: lib/____var-ark_app_path-var____/Controller/____var-ark_target_path-var____.pm
template: |
  package [% ark_app %]::Controller::[% ark_target %];
  use Ark '[% ark_base_class %]';
  
  1;

---
config:
  plugins:
    - Template
    - Additional
    - +Ark::Command::Flavor::Controller

