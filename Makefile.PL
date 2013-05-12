use strict;
use warnings;

use inc::Module::Install;
$Module::Install::AUTHOR = 0 if $ENV{TRAVIS};

name 'Ark';
license 'perl';
all_from 'lib/Ark.pm';

perl_version '5.008001';
cpanfile;

author_tests('xt');
no_index directory => qw(t xt inc eg tools);

WriteAll;
