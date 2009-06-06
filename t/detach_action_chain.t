use Test::Base;

{
    package TestApp;
    use Ark;

    package TestApp::Controller::Root;
    use Ark 'Controller';
    has '+namespace' => default => '';

    sub default :Private {
        my ($self, $c) = @_;
        $c->res->body('404');
    }

    package TestApp::Controller::Entry;
    use Ark 'Controller';

    sub entry :Chained('/') :PathPart('entry') :CaptureArgs(1) {
        my ($self, $c, $entry_id) = @_;
        $c->stash->{entry} = "entry$entry_id";
        $c->detach('/default') if $entry_id eq '0';
    }

    sub index :Chained('entry') :PathPart('') :Args(0) {
        my ($self, $c) = @_;
        $c->res->body( $c->stash->{entry} );
    }
}

use Ark::Test 'TestApp',
    components => [qw/Controller::Root Controller::Entry/];

plan 'no_plan';

{
    my $res = request( GET => '/entry/1' );
    ok($res->is_success, 'response ok');
    is($res->content, 'entry1', 'chained without detach response ok');
}

{
    my $res = request( GET => '/entry/0' );
    ok($res->is_success, 'response ok');
    is($res->content, '404', 'chained with detach response ok');
}

