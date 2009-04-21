use inc::Module::Install;
name 'Ark';
all_from 'lib/Ark.pm';

test_requires 'Test::More';

requires 'perl' => '5.008001';
requires 'HTTP::Engine' => '0.001004';
requires 'Mouse'        => '0.21';
requires 'Path::Class'  => '0.16';
requires 'URI';
requires 'Text::SimpleTable';
requires 'Module::Pluggable::Object';
requires 'Data::Util';

features(
    'View::MT' => [
        -default => 1,
        recommends('Text::MicroTemplate'),
    ],
);

use_test_base;
auto_include;
WriteAll;
