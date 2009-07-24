package Ark::Models;
use strict;
use warnings;
use utf8;
use base 'Object::Container';

use Path::Class qw/file dir/;

sub import {
    my $pkg  = shift;
    my $flag = shift || 'model';

    utf8->import;

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

    unshift @_, $pkg, $flag;
    goto $pkg->can('SUPER::import');
}

1;
