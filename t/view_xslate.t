use Test::Base;
use FindBin;

eval { require Text::Xslate; };
plan skip_all => 'this test required Text::Xslate' if $@;

{
    package TestApp;
    use Ark;

    package TestApp::Controller::Root;
    use Ark 'Controller';

    has '+namespace' => default => '';

    sub forward :Local {
        my ($self, $c) = @_;
        $c->forward( $c->view('Xslate') );
    }

    sub render :Local {
        my ($self, $c) = @_;
        my $body = $c->view('Xslate')->render('render');
        $c->res->body($body);
    }

    sub template :Local {
        my ($self, $c) = @_;
        $c->view('Xslate')->template('forward');
        $c->forward('forward');
    }

    sub include :Local {
        my ($self, $c) = @_;
        $c->forward( $c->view('Xslate') );
    }

    package TestApp::View::Xslate;
    use Ark 'View::Xslate';

    has '+path' => (
        default => sub { ["$FindBin::Bin/view_xslate"] },
    );
}

plan 'no_plan';

use Ark::Test 'TestApp',
    components => [qw/Controller::Root View::Xslate/];

{
    my $content = get('/forward');
    is($content, 'index xslate', 'forward view ok');
}

{
    my $content = get('/render');
    is($content, 'render xslate', 'render view ok');
}

{
    my $content = get('/template');
    is($content, 'index xslate', 'set template view ok');
}

{
    my $content = get('/include');
    is($content, 'before included after', 'include ok');
}

