use Test::Base;

{
    package T1;
    use Ark;

    package T1::Controller::Root;
    use Ark 'Controller';

    has '+namespace' => default => '';

    sub default :Path {
        my ($self, $c) = @_;
        $c->res->status(404);
        $c->res->body('404 Not Found');
    }

    sub render :Private {
        my ($self, $c, @path) = @_;

        my $date = q[];
        my ($yr, $mo, $da) = @{$c->stash}{qw/year month day/};
        if ($yr && $mo && $da) {
            $date = sprintf '%04d-%02d-%02d', $yr, $mo, $da;
        }
        elsif ($yr && $mo) {
            $date = sprintf '%04d-%02d', $yr, $mo;
        }
        elsif ($yr) {
            $date = $yr;
        }

        $c->res->body("${date}: " . join ',', @path);
    }

    sub day :Regex('^(\d{4})/([01]?\d)/([0-3]?\d)(?:/(.*))?') {
        my ($self, $c, $yr, $mo, $da, $rest) = @_;

        @{$c->stash}{qw/year month day/} = ($yr, $mo, $da);
        $c->forward('render', split '/', $rest);
    }

    sub month :Regex('^(\d{4})/([01]?\d)(?:/(.*))?') {
        my ($self, $c, $yr, $mo, $rest) = @_;

        @{$c->stash}{qw/year month/} = ($yr, $mo);
        $c->forward('render', split '/', $rest);
    }

    sub year :Regex('^(\d{4})(?:/(.*))?') {
        my ($self, $c, $yr, $rest) = @_;

        $c->stash->{year} = $yr;
        $c->forward('render', split '/', $rest);
    }
}

plan 'no_plan';

use Ark::Test 'T1', components => [qw/Controller::Root/];

is(get('/2009/01/11/foo/bar'), '2009-01-11: foo,bar');
is(get('/2009/01/foo/bar/baz'), '2009-01: foo,bar,baz');
is(get('/2009/foo/bar'), '2009: foo,bar');

