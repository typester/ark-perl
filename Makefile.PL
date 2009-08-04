use inc::Module::Install;

name 'Ark';
license 'perl';

all_from 'lib/Ark.pm';

test_requires 'Test::More';

perl_version '5.008001';

requires 'HTTP::Engine' => '0.001008';
requires 'Mouse'        => '0.21';
requires 'Path::Class'  => '0.16';
requires 'URI';
requires 'Text::SimpleTable';
requires 'Module::Pluggable::Object';
requires 'Data::Util';
requires 'Class::Data::Inheritable';
requires 'HTML::Entities';
requires 'Data::UUID';
requires 'Digest::SHA1';
requires 'Devel::StackTrace';
requires 'Class::Method::Modifiers::Fast';
requires 'Exporter::AutoClean';
requires 'Object::Container' => '0.03';

# for build-in server
requires 'HTTP::Engine::Middleware' => '0.13';
requires 'MIME::Types';
requires 'MouseX::Types::Path::Class';
requires 'Getopt::Long' => '2.36';

# build-in helper script
requires 'Module::Setup';
requires 'FindBin::libs';

features(
    'Support MicroTemplate template engine' => [
        -default => 1,
        recommends('Text::MicroTemplate::Extended' => '0.04'),
    ],
    'Support DBIx::Class OR Mapper' => [
        -default => 0,
        recommends('DBIx::Class'),
        recommends('DBIx::Class::Schema::Loader'),
        recommends('DBD::SQLite'),
    ],
    'Support OpenID Authentication' => [
        -default => 0,
        recommends('Net::OpenID::Consumer'),
        recommends('LWPx::ParanoidAgent'),
    ],
);

use_test_base;

auto_include;
auto_install;

install_script 'script/ark.pl';

WriteAll;
