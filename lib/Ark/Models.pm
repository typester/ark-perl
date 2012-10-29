package Ark::Models;
use Any::Moose;

BEGIN { do { eval q[use MouseX::Foreign; 1] or die $@ } if any_moose eq 'Mouse' }

extends any_moose('::Object'), 'Object::Container';

use Exporter::AutoClean;
use Path::Class qw/file dir/;

has registered_namespaces => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
);

has [qw/registered_classes objects/] => ( is => 'rw', default => sub { {} } );

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

        $pkg->initialize;
    }

    unshift @_, $pkg, $flag;
#    goto $pkg->can('SUPER::import');
    goto &Object::Container::import; # Some perl does not run avobe code, this is a quick fix for it.
}

sub initialize {
    my $pkg = shift;

    # build-in models: home, conf
    $pkg->register(
        home => sub {
            return dir($ENV{ARK_HOME}) if $ENV{ARK_HOME};

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
                    my $c = do $file;
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

sub ensure_class_loaded {
    Any::Moose::load_class($_[1]);
}

__PACKAGE__->meta->make_immutable;
