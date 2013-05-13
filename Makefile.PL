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

features(
    'Support MicroTemplate template engine' => [
        -default => 1,
        recommends('Text::MicroTemplate::Extended' => '0.09'),
    ],
    'Support DBIx::Class OR Mapper' => [
        -default => 0,
        recommends('DBIx::Class'),
        recommends('DBD::SQLite'),
    ],
    'Support OpenID Authentication' => [
        -default => 0,
        recommends('Net::OpenID::Consumer'),
        recommends('LWPx::ParanoidAgent'),
    ],
    'Support I18N' => [
        -default => 1,
        recommends('Locale::Maketext::Lexicon'),
        recommends('Locale::Maketext::Simple'),
    ],
    'Support Mobile App' => [
        -default => 0,
        recommends('Encode::JP::Mobile'),
        recommends('HTTP::MobileAgent'),
        recommends('HTTP::MobileAgent::Plugin::Charset'),
        recommends('OAuth::Lite'),
    ],
);

WriteAll;
