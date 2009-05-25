package Ark::Command::Flavor::Newapp;
use strict;
use warnings;

use base qw/Module::Setup::Plugin Module::Setup::Flavor/;

sub register {
    my $self = shift;
    $self->add_trigger(after_setup_module_attribute
                           => $self->can('setup_module_attribute') );
    $self->add_trigger(after_setup_template_vars
                           => $self->can('setup_template_vars') );
}

sub setup_module_attribute { }

sub setup_template_vars {
    my $setup = shift;

    
}

1;

__DATA__

---
file: Makefile.PL
template: |
  use inc::Module::Install;
  name '[% dist %]';
  all_from 'lib/[% module_path %].pm';

  requires 'Ark';

  tests 't/*.t';

  build_requires 'Test::More';
  use_test_base;
  auto_include;
  WriteAll;
---
file: t/00_compile.t
template: |
  use strict;
  use Test::More tests => 1;

  BEGIN { use_ok '[% module %]' }
---
file: lib/____var-module_path-var____.pm
template: |
  package [% module %];
  use Ark;

  our $VERSION = '0.01';

  1;
---
file: lib/____var-module_path-var____/Controller/Root.pm
template: |
  package [% module %]::Controller::Root;
  use Ark 'Controller';

  has '+namespace' => default => '';

  # default 404 handler
  sub default :Path :Args {
      my ($self, $c) = @_;

      $c->res->status(404);
      $c->res->body('404 Not Found');
  }

  sub index :Path :Args(0) {
      my ($self, $c) = @_;
      $c->res->body('Ark Default Index');
  }

  1;

---
dir: root
---
dir: tmp
---
config:
  plugins:
    - Template
    - Additional
    - +Ark::Command::Flavor::Newapp

