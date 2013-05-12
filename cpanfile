on develop => sub {
    requires 'Module::Install';
    requires 'Module::Install::AuthorTests';
    requires 'Module::Install::CPANfile';
};

on test => sub {
    requires 'Test::More' => '0.96';
    requires 'Test::Output';
};

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

feature 'MT', 'Support MicroTemplate template engine' => sub {
    recommends 'Text::MicroTemplate::Extended' => '0.09';
};

feature 'DBIC', 'Support DBIx::Class OR Mapper' => sub {
    suggests 'DBIx::Class';
    suggests 'DBD::SQLite';
};

feature 'OpenID', 'Support OpenID Authentication' => sub {
    suggests 'Net::OpenID::Consumer';
    suggests 'LWPx::ParanoidAgent';
};

feature 'I18N', 'Support I18N' => sub {
    recommends 'Locale::Maketext::Lexicon';
    recommends 'Locale::Maketext::Simple';
};

feature 'Mobile', 'Support Mobile App' => sub {
    suggests 'Encode::JP::Mobile';
    suggests 'HTTP::MobileAgent';
    suggests 'HTTP::MobileAgent::Plugin::Charset';
    suggests 'OAuth::Lite';
};
