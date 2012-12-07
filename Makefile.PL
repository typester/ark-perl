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
requires 'Any::Moose'   => '0.11';
requires 'Try::Tiny' => '0.02';
requires 'Path::Class'  => '0.16';
requires 'URI';
requires 'URI::WithBase';
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
requires 'Object::Container' => '0.08';
requires 'Path::AttrRouter' => '0.02';
requires 'MouseX::Foreign';

# build-in form generator/validator
requires 'HTML::Shakan' => '0.03';
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

if ($ENV{ANY_MOOSE_TEST} && author_context()) {
    # gfx++
    # repeat testing
    # see also ExtUtils::MM_Any::test_via_harness()
    my $test_moose = q{$(FULLPERLRUN) -MExtUtils::Command::MM -e}
                    .q{ "do 'tools/force-moose.pl'; }
                    .q{test_harness($(TEST_VERBOSE), '$(INST_LIB)', '$(INST_ARCHLIB)')"}
                    .q{ $(TEST_FILES)} . "\n";

    postamble qq{test_dynamic :: moose\n\n}
            . qq{moose ::\n}
            . qq{\t} . $test_moose;
}

WriteAll;
