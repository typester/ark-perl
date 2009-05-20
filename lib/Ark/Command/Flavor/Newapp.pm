package Ark::Command::Flavor::Newapp;
use Mouse;

extends 'Mouse::Object', 'Module::Setup::Flavor';

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
file: root/.gitignore
template: ''
---
file: tmp/.gitignore
template: ''
---
config:
  plugins:
    - Template
    - Additional
