use inc::Module::Install;

name 'Ark';
license 'perl';

all_from 'lib/Ark.pm';

test_requires 'Test::More' => '0.96';
test_requires 'Test::Output';

perl_version '5.008001';

requires 'Plack';
requires 'Plack::Request';
requires 'CGI::Simple';
requires 'Mouse'   => '1.0';
requires 'Try::Tiny' => '0.02';
requires 'Path::Class'  => '0.16';
requires 'URI';
requires 'URI::WithBase';
requires 'Text::MicroTemplate';
requires 'Text::SimpleTable';
requires 'Module::Pluggable::Object';
requires 'Data::Util';
requires 'Class::Data::Inheritable';
requires 'HTML::Entities';
requires 'Data::UUID';
requires 'Digest::SHA1';
requires 'Devel::StackTrace';
requires 'Exporter::AutoClean';
requires 'Object::Container' => '0.08';
requires 'Path::AttrRouter'  => '0.03';

# build-in form generator/validator
requires 'HTML::Shakan' => '0.16';
requires 'Clone';

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

use_test_base;
author_tests('xt');

WriteAll;
