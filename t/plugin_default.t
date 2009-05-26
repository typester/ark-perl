use Test::Base;
require Ark::Test;

{
    package T1;
    use Ark;

    package T1::Controller::Root;
    use Ark 'Controller';

    use Test::More;

    __PACKAGE__->config( namespace => '' );

    sub default :Path {
        my ($self, $c) = @_;
        my %plugins = map { $_->name => 1 } @{ $c->meta->roles };

        ok( $plugins{'Ark::Plugin::Encoding::Unicode'}, 'default plugin loaded ok' );
    }
}

{
    package T2;
    use Ark;

    use_plugins 'Encoding::Null';

    package T2::Controller::Root;
    use Ark 'Controller';

    use Test::More;

    __PACKAGE__->config( namespace => '' );

    sub default :Path {
        my ($self, $c) = @_;
        my %plugins = map { $_->name => 1 } @{ $c->meta->roles };

        ok( !$plugins{'Ark::Plugin::Encoding::Unicode'}, 'default plugin not loaded ok' );
    }
}

plan 'no_plan';

import Ark::Test 'T1', components => [qw/Controller::Root/];

get('/');

import Ark::Test 'T2', components => [qw/Controller::Root/];

get('/');
