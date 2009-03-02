use Test::Base;

{
    package TestApp;
    use Ark;

    package TestApp::Controller::Root;
    use Ark 'Controller';

    sub one :Local {
        my ($self, $c) = @_;
        $c->res->{body} .= 'one_';
        $c->forward('two');
    }

    sub two :Local {
        my ($self, $c) = @_;
        $c->res->{body} .= 'two_';
        $c->forward('three');
    }

    sub three :Local {
        my ($self, $c) = @_;
        $c->res->{body} .= 'tree_';
        $c->forward($self);
    }

    # four
    sub process {
        my ($self, $c) = @_;
        $c->res->{body} .= 'four_';
        $c->forward('/root/five');
    }

    sub five :Local {
        my ($self, $c) = @_;
        $c->res->{body} .= 'five_';
        $c->forward('six');
    }

    sub six :Path {
        my ($self, $c) = @_;
        $c->res->{body} .= 'six_';
    }
}

use Ark::Test 'TestApp',
    components => [qw/Controller::Root/];

plan 'no_plan';

{
    my $res = request( GET => '/root/one' );
    ok( $res->is_success, 'request ok');
    is( $res->content, 'one_two_tree_four_five_six_', 'forward ok');
}

