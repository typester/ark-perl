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

    my $libdir = dir(cwd)->subdir('lib');
    $self->show_usage(-1, "There is no 'lib' directory in current directory")
        unless -d $libdir;

    eval "use lib q[$libdir]";
    die $@ if $@;

    my $extlib = $libdir->parent->subdir('extlib');
    if (-d $extlib) {
        eval "use lib q[$extlib]";
    }

    my $app_name = $args[0];
    if ($app_name) {
        eval "use $app_name";
        if ($@) {
            $self->show_usage(-1, qq[Can't find app: "$app_name"]);
        }
    }
    else {
        # search ark application
        $libdir->recurse( callback => sub {
            my $file = $_[0];
            return if $app_name;
            return unless -f $file && $file->basename =~ /\.pm$/;

            my $path = $libdir;
            if ($^O eq 'MSWin32') {
                $file =~ s!\\!/!g;
                $path =~ s!\\!/!g;
            }
            (my $module = $file) =~ s!^$path/!!;
            $module =~ s!/!::!g;
            $module =~ s!\.pm$!!;

            Mouse::load_class($module) unless Mouse::is_class_loaded($module);

            return unless $module->can('meta')
                and ref($module->meta) eq 'Mouse::Meta::Class';

            my @super = $module->meta->superclasses;
            $app_name = $module if grep /^Ark::Core$/, @super;
        });

        $self->show_usage(-1, qq[Error: Can't find ark application in 'lib' directory\n])
            unless $app_name;
    }

    my $app = $app_name->new;
    $app->log_level( $self->options->{debug} ? 'debug' : 'error' );
    $app->setup;

    my $mw = HTTP::Engine::Middleware->new;
    $mw->install('HTTP::Engine::Middleware::Static' => {
        docroot => $app->path_to('root'),
        regexp => '/(?:(?:css|js|img|images?|swf|static|tmp|)/.*|[^/]+\.[^/]+)',
#        regexp => qr!^/.*!,
#        is_404_handler => 0, # this option requires HEM 0.14 or later
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
