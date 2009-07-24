package Ark::Models;
use strict;
use warnings;
use utf8;
use base 'Object::Container';

use Path::Class qw/file dir/;

sub import {
    my $pkg  = shift;
    my $flag = shift || 'model';

    if (($flag || '') =~ /^-base$/i) {
        utf8->import;
    }
    else {
        if ($pkg eq __PACKAGE__) {
            die q[Don't use Ark::Model directly. You must create your own subclasses];
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

1;
