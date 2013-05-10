use strict;
use warnings;
use Test::More;
use FindBin;

eval { require Text::MicroTemplate::Extended; };
plan skip_all => 'this test required Text::MicroTemplate::Extended' if $@;

{
    package TestApp;
    use Ark;

    package TestApp::Controller::Root;
    use Ark 'Controller';

    has '+namespace' => default => '';

    sub forward :Local {
        my ($self, $c) = @_;
        $c->forward( $c->view('MT') );
    }

    sub render :Local {
        my ($self, $c) = @_;
        my $body = $c->view('MT')->render('render');
        $c->res->body($body);
    }

    sub template :Local {
        my ($self, $c) = @_;
        $c->view('MT')->template('forward');
        $c->forward('forward');
    }

    sub include :Local {
        my ($self, $c) = @_;
        $c->forward( $c->view('MT') );
    }

    package TestApp::View::MT;
    use Ark 'View::MT';

    has '+include_path' => (
        default => sub { ["$FindBin::Bin/view_mt"] },
    );
}


use Ark::Test 'TestApp',
    components => [qw/Controller::Root View::MT/];

{
    my $content = get('/forward');
    is($content, 'index mt', 'forward view ok');
}

{
    my $content = get('/render');
    is($content, 'render mt', 'render view ok');
}

{
    my $content = get('/template');
    is($content, 'index mt', 'set template view ok');
}

{
    my $content = get('/include');
    is($content, 'before included[foo,bar] after', 'include ok');
}

done_testing;
