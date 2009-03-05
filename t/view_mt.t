use Test::Base;
use FindBin;

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

    package TestApp::View::MT;
    use Ark 'View::MT';

    __PACKAGE__->config(
        include_path => ["$FindBin::Bin/view_mt"],
    );
}

plan 'no_plan';

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

