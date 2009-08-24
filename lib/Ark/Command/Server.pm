package Ark::Command::Server;
use Mouse;

with 'Ark::Command::Interface';

use Cwd qw/cwd/;
use Path::Class qw/dir/;

use HTTP::Engine;
use HTTP::Engine::Middleware;

no Mouse;

sub option_list {
    qw/help debug port=i address=s/
}

sub run {
    my ($self, @args) = @_;
    $self->show_usage(0) if $self->options->{help};

    my $app_name = $self->search_app($args[0]);

    my $app = $app_name->new;
    $app->log_level( $self->options->{debug} ? 'debug' : 'error' );
    $app->setup;

    my $mw = HTTP::Engine::Middleware->new;
    $mw->install('HTTP::Engine::Middleware::Static' => {
        docroot => $app->path_to('root'),
#        regexp => '/(?:(?:css|js|img|images?|swf|static|tmp|)/.*|[^/]+\.[^/]+)',
        regexp => qr!^/.*!,
        is_404_handler => 0, # this option requires HEM 0.14 or later
    });

    HTTP::Engine->new(
        interface  => {
            module => 'ServerSimple',
            args   => {
                host => $self->options->{address} || '0.0.0.0',
                port => $self->options->{port}    || 4423,
            },
            request_handler => $mw->handler( $app->handler ),
        },
    )->run;
}

1;

__END__

=head1 NAME

Ark::Command::Server - ark.pl subcommand 'server'

=head1 SYNOPSIS

 ark.pl server [options] [app name]

 Options:
   -h --help    show this help
   -d --debug   enable debug mode [default: off]
   -p --port    specify port number to listen [default: 4423]
   -a --address specify address to bind [default: 0.0.0.0]

 If it is not passed [app name], try auto-detect.

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=cut
