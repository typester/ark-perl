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
        $c->forward( $c->view('TT') );
    }

    sub render :Local {
        my ($self, $c) = @_;
        my $body = $c->view('TT')->render('render');
        $c->res->body($body);
    }

    sub template :Local {
        my ($self, $c) = @_;
        $c->view('TT')->template('forward');
        $c->forward('forward');
    }

    sub include :Local {
        my ($self, $c) = @_;
        $c->forward( $c->view('TT') );
    }

    package TestApp::View::TT;
    use Ark 'View::TT';

    has '+include_path' => (
        default => sub { ["$FindBin::Bin/view_tt"] },
    );
}

plan 'no_plan';

use Ark::Test 'TestApp',
    components => [qw/Controller::Root View::TT/];

{
    my $content = get('/forward');
    is($content, 'index tt', 'forward view ok');
}

{
    my $content = get('/render');
    is($content, 'render tt', 'render view ok');
}

{
    my $content = get('/template');
    is($content, 'index tt', 'set template view ok');
}

{
    my $content = get('/include');
    is($content, 'before included after', 'include ok');
}

