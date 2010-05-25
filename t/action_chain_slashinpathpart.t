use Test::More;

{
    package T1;
    use Ark;

    package T1::Controller::Root;
    use Ark 'Controller';

    has '+namespace' => default => '';

    sub foo :Chained('/') :CaptureArgs(1) {
        my ($self, $c, $bar) = @_;
        $c->stash->{bar} = $bar;
    }

    sub end :Chained('foo') :PathPart('hoge/fuga') :Args(0) {
        my ($self, $c, $end) = @_;
        $c->res->body( $c->stash->{bar} . ($end || '') );
    }
}

use Ark::Test 'T1', components => [qw/Controller::Root/];

is get('/foo/bar/hoge/fuga'), 'bar',
    'slash in pathpart ok';

done_testing;
