package Ark;
use 5.008001;
use Any::Moose;
use Any::Moose '::Exporter';

our $VERSION = '0.10';

do {
    my @super;
    sub init_meta {
        my ($class) = @_;
        require utf8; import utf8;

        my @superclasses;
        push @super, 'Core' unless @super;
        for my $target (@super) {
            my $pkg;
            if ($target =~ /^\+/) {
                ($pkg = $target) =~ s/^\+//;
            }
            else {
                $pkg = "Ark::${target}";
            }
            push @superclasses, $pkg;
            Any::Moose::load_class($pkg) unless Any::Moose::is_class_loaded($pkg);

            no strict 'refs';
            for my $keyword (@{$pkg . '::EXPORT'}) {
                *{ $class . '::' . $keyword } = *{ $pkg . '::' . $keyword };
            }

            if (my $exporter = $pkg->can('EXPORT')) {
                $exporter->($pkg, $class);
            }
        }

        my $meta = any_moose('::Meta::Class')->initialize($class);
        $meta->superclasses(@superclasses);

        $meta;
    }

    my $next;
    BEGIN {
        any_moose('::Exporter')->setup_import_methods(
            also => any_moose,
        );
        $next = __PACKAGE__->can('import');
    }

    no warnings 'redefine';
    sub import {
        my ($class, @target) = @_;
        @super = @target;
        @_ = ($class);
        goto \&$next;
    }
};

1;
