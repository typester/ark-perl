package Ark::Test;
use Mouse;

use HTTP::Request;
use HTTP::Engine;
use HTTP::Cookies;

use FindBin;
use Path::Class qw/dir/;

use Ark::Test::Context;

sub import {
    my ($class, $app_class, @rest) = @_;
    my $caller = caller;
    my %option = @rest;

    return unless $app_class;

    Mouse::load_class($app_class) unless Mouse::is_class_loaded($app_class);

    my $persist_app = undef;
    my $cookie;

    {
        no strict 'refs';
        no warnings 'redefine';

        *{ $caller . '::request'} = sub {
            my $app;
            unless ($persist_app) {
                $app = $app_class->new;

                my @components = map { "${app_class}::${_}" }
                    @{ $option{components} || [] };
                $app->load_component($_) for @components;

                if ($option{minimal_setup}) {
                    $app->setup_home;

                    $app->path_to('action.cache')->remove;

                    my $child = fork;
                    if ($child == 0) {
                        $app->setup_minimal;
                        exit;
                    }
                    elsif (!defined($child)) {
                        die $!;
                    }

                    waitpid $child, 0;

                    $app->setup_minimal;
                }
                else {
                    $app->setup;
                }
                $app->config->{home} ||= dir($FindBin::Bin);
            }

            if ($option{reuse_connection}) {
                if ($persist_app) {
                    $app = $persist_app;
                }
                else {
                    $persist_app = $app;
                    $cookie = HTTP::Cookies->new;
                }
            }

            my $req = ref($_[0]) eq 'HTTP::Request' ? $_[0] : HTTP::Request->new(@_);
            if ($cookie) {
                $req->uri( URI->new('http://localhost' . $req->uri->path ) );
                $req->header( Host => 'localhost' );
                $cookie->add_cookie_header($req);
            }

            my $res = HTTP::Engine->new(
                interface => {
                    module          => 'Test',
                    request_handler => $app->handler,
                },
            )->run($req, env => \%ENV);

            if ($cookie) {
                $res->{_request} = $req;
                $cookie && $cookie->extract_cookies($res);
            }

            $app->path_to('action.cache')->remove if $option{minimal_setup};

            $res;
        };

        *{ $caller . '::get' } = sub {
            &{$caller . '::request'}(GET => @_)->content;
        };

        *{ $caller . '::reset_app' } = sub() {
            undef $persist_app;
            undef $cookie;
        };

        *{ $caller . '::ctx_request'} = sub {
            unless (Ark::Context->meta->does_role('Ark::Test::Context')) {
                Ark::Test::Context->meta->apply( Ark::Context->meta );
            }

            my $res = &{$caller . '::request'}(@_);
            return $res, context();
        };

        *{ $caller . '::ctx_get' } = sub {
            my ($res, $c) = &{$caller . '::ctx_request'}(GET => @_);
            return $res->content, $c;
        };
    }
}

do {
    my $context;
    sub context {
        if ($_[0]) {
            $context = $_[0];
        }
        $context;
    }
};

1;

