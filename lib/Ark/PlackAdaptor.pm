package Ark::PlackAdaptor;
use strict;
use warnings;
use HTTP::Engine;

sub new {
    my($class, $app) = @_;
    bless { app => $app }, $class;
}

sub handler {
    my $self = shift;

    my $app = $self->{app}->new;
    $app->setup;

    my $engine = HTTP::Engine->new(
        interface => {
            module => 'PSGI',
            request_handler => $app->handler,
        }
    );

    return sub { $engine->run(@_) };
}

1;
