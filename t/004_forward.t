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

    sub seven : Local {
        my ( $self, $c ) = @_;
        $c->forward( 'eight', 'seven_' );
    }

    sub eight : Local {
        my ( $self, $c, $seven ) = @_;
        $c->res->{body} .= "${seven}eight_";
    }

    sub request_args :Local :Args(2) {
        my ($self, $c, $foo, $bar) = @_;
        $c->forward('request_args_check');
    }

    sub request_args_check :Private {
        my ($self, $c, $foo, $bar) = @_;
        $c->res->body(join ',', $foo, $bar);
    }

    sub capture_args :Regex('^capture_args/(.*?)/(.*?)$') {
        my ($self, $c, $foo, $bar) = @_;
        $c->res->body(join ',', $foo, $bar);
    }

    sub forward_capture_args :Regex('^forward_capture_args/(.*?)/(.*?)$') {
        my ($self, $c, $foo, $bar) = @_;
        $c->forward('forward_capture_args_check');
    }

    sub forward_capture_args_check :Private {
        my ($self, $c, $foo, $bar) = @_;
        $c->res->body(join ',', $foo, $bar);
    }

    use Test::More;
    sub return_undef_check :Local {
        my ($self, $c) = @_;

        is($c->state, 0, 'initial state ok');

        my $state = $c->forward('just_return');
        is($state, undef, 'undef state ok');
    }

    sub just_return :Private {
        my ($self, $c) = @_;
        return;
    }
}

require Ark::Test;

plan 'no_plan';

sub run_tests() {
    {
        my $res = request( GET => '/root/one' );
        ok( $res->is_success, 'request ok');
        is( $res->content, 'one_two_tree_four_five_six_', 'forward ok');
    }

    {
        my $res = request( GET => '/root/seven' );
        ok( $res->is_success, 'request ok');
        is( $res->content, 'seven_eight_', 'forward ok');
    }

    {
        my $res = request( GET => '/root/request_args/FOO/BAR' );
        ok( $res->is_success, 'request ok');
        is( $res->content, 'FOO,BAR', 'request args ok');
    }

    {
        my $res = request( GET => '/capture_args/FOO/BAR' );
        ok( $res->is_success, 'request ok');
        is( $res->content, 'FOO,BAR', 'capture args ok');
    }

    {
        my $res = request( GET => '/forward_capture_args/FOO/BAR' );
        ok( $res->is_success, 'request ok');
        is( $res->content, 'FOO,BAR', 'forward capture args ok');
    }

    {
        get('/root/return_undef_check');
    }
}

import Ark::Test 'TestApp',
    components => [qw/Controller::Root/];

run_tests;

import Ark::Test 'TestApp',
    components => [qw/Controller::Root/],
    minimal_setup => 1;

run_tests;
