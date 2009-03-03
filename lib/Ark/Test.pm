package Ark::Test;
use Mouse;

use HTTP::Request;
use HTTP::Engine;

sub import {
    my ($class, $app_class, @rest) = @_;
    my $caller = caller;

    my %option = @rest;

    Mouse::load_class($app_class) unless Mouse::is_class_loaded($app_class);

    {
        no strict 'refs';
        *{ $caller . '::request'} = sub {
            my $app = $app_class->new;

            my @components = map { "${app_class}::${_}" } @{ $option{components} || [] };
            $app->load_component($_) for @components;

            $app->setup;

            my $req = ref($_[0]) eq 'HTTP::Request' ? $_[0] : HTTP::Request->new(@_);

            HTTP::Engine->new(
                interface => {
                    module          => 'Test',
                    request_handler => $app->handler,
                },
            )->run($req, env => \%ENV);
        };

        *{ $caller . '::get' } = sub {
            &{$caller . '::request'}(GET => @_)->content;
        }
    }
}

1;

