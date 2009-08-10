package Ark::Models;
use Any::Moose;

extends 'Object::Container';

use Exporter::AutoClean;
use Path::Class qw/file dir/;

has registered_namespaces => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
);

no Any::Moose;

sub import {
    my $pkg    = shift;
    my $flag   = shift || 'models';
    my $caller = caller;

    if (($flag || '') =~ /^-base$/i) {
        utf8->import;

        Exporter::AutoClean->export(
            scalar caller,
            register_namespaces => sub { $caller->register_namespaces(@_) },
        );
    }
    else {
        if ($pkg eq __PACKAGE__) {
            die q[Don't use Ark::Model directly. You must create your own subclasses];
        }

        if ($caller->can($flag)) {
            die
              qq[Can't initialize $pkg, method "$flag" is already defined in "$caller"];
        }

        $pkg->initialize;
    }

    unshift @_, $pkg, $flag;
    goto $pkg->can('SUPER::import');
}

sub initialize {
    my $pkg = shift;

    # build-in models: home, conf
    $pkg->register(
        home => sub {
            return $ENV{ARK_HOME} if $ENV{ARK_HOME};

            my $class = shift;

            $class = ref $class || $class;
            (my $file = "${class}.pm") =~ s!::!/!g;

            if (my $path = $INC{$file}) {
                $path =~ s/$file$//;

                $path = dir($path);

                if (-d $path) {
                    $path = $path->absolute;
                    while ($path->dir_list(-1) =~ /^b?lib$/) {
                        $path = $path->parent;
                    }

                    return $path;
                }
            }

            die 'Cannot detect home directory, please set it manually: $ENV{ARK_HOME}';
        },
    );

    $pkg->register(
        conf => sub {
            my $home = shift->get('home');

            my $conf = {};
            for my $fn (qw/config.pl config_local.pl/) {
                my $file = $home->file($fn);
                if (-e $file) {
                    my $c = require $file;
                    die 'config should return HASHREF'
                        unless ref($c) and ref($c) eq 'HASH';

                    $conf = { %$conf, %$c };
                }
            }

            $conf;
        },
    );

    $pkg->register_namespaces( '' => $pkg );
}

sub adaptor {
    my ($self, $info) = @_;

    my $class       = $info->{class} or die q{Required class parameter};
    my $constructor = $info->{constructor} || 'new';

    $self->ensure_class_loaded($class);

    my $instance;
    if ($info->{deref} and my $args = $info->{args}) {
        if (ref($args) eq 'HASH') {
            $instance = $class->$constructor(%$args);
        }
        elsif (ref($args) eq 'ARRAY') {
            $instance = $class->$constructor(@$args);
        }
        else {
            die qq{Couldn't dereference: $args};
        }
    }
    elsif ($info->{args}) {
        $instance = $class->$constructor($info->{args});
    }
    else {
        $instance = $class->$constructor;
    }

    $instance;
}

sub register_namespaces {
    my ($self, %namespaces) = @_;
    $self = $self->instance unless ref $self;

    while (my ($name, $ns) = each %namespaces) {
        $self->registered_namespaces->{ $name } = $ns;
    }
}

sub get {
    my $self = shift;
    $self    = $self->instance unless ref $self;

    my $obj  = eval { $self->SUPER::get(@_) };
    my $err  = $@;

    return $obj if $obj;

    my $target = $_[0];
    if ($target =~ /::/) {
        my ($ns, @classes);
        while ($target =~ s/::(.*?)$//) {
            unshift @classes, $1;
            $ns = $self->registered_namespaces->{$target} and last;
        }
        die $err unless $ns;

        my $class = $ns . '::' . join '::', @classes;

        $self->ensure_class_loaded($class);
        return $self->objects->{ $_[0] } = $class->new;
    }
    else {
        die $err;
    }
}

1;
