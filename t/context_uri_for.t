package MyApp;
use Ark;

package MyApp::Controller::Root;
use Ark 'Controller';

sub default : Path('/') {
    my ( $self, $c ) = @_;
    $c->response->body( $c->uri_for('/root') );
}

sub admin : Path('/admin') {
    my ( $self, $c ) = @_;
    $c->response->body( $c->uri_for('/admin') );
}


package main;
use strict;
use warnings;
use Plack::Builder;
use Test::More;
use Plack::Test;
$Plack::Test::Impl = "MockHTTP";

my $app = MyApp->new;
$app->setup;

my $root = builder {
    my $env = shift;
    mount '/' => $app->handler;
};

my $admin = builder {
    my $env = shift;
    mount '/admin' => $app->handler;
};

my $admin_slash = builder {
    my $env = shift;
    mount '/admin/' => $app->handler;
};


test_psgi
  app    => $root,
  client => sub {
    my $cb  = shift;
    my $req = HTTP::Request->new( GET => "http://localhost/" );
    my $res = $cb->($req);
    is $res->content, 'http://localhost/root';
    is $res->code,    200;

    $req = HTTP::Request->new( GET => "http://localhost/admin" );
    $res = $cb->($req);
    is $res->content, 'http://localhost/admin';
    is $res->code,    200;

  };

test_psgi
  app    => $admin,
  client => sub {
    my $cb  = shift;
    my $req = HTTP::Request->new( GET => "http://localhost/admin" );
    my $res = $cb->($req);
    is $res->content, 'http://localhost/admin/root';
    is $res->code,    200;

    $req = HTTP::Request->new( GET => "http://localhost/admin/admin" );
    $res = $cb->($req);
    is $res->content, 'http://localhost/admin/admin';
    is $res->code,    200;

  };

test_psgi
  app    => $admin_slash,
  client => sub {
    my $cb  = shift;
    my $req = HTTP::Request->new( GET => "http://localhost/admin" );
    my $res = $cb->($req);
    is $res->content, 'http://localhost/admin/root';
    is $res->code,    200;

    $req = HTTP::Request->new( GET => "http://localhost/admin/admin" );
    $res = $cb->($req);
    is $res->content, 'http://localhost/admin/admin';
    is $res->code,    200;
  };

done_testing;
