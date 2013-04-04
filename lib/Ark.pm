package Ark;
use 5.008001;
use Mouse;
use Mouse::Exporter;

use Ark::Core;

our $VERSION = '0.30';

do {
    my %EXPORTS;

    sub import {
        my ($class, @bases) = @_;

        my $caller = caller;

        require utf8; import utf8;

        my @super;
        push @bases, 'Core' unless @bases;
        for my $base (@bases) {
            my $pkg;
            if ($base =~ /^\+/) {
                ($pkg = $base) =~ s/^\+//;
            } else {
                $pkg = "Ark::${base}";
            }
            push @super, $pkg;
            Ark::Core->ensure_class_loaded($pkg);

            no strict 'refs';
            for my $keyword (@{ $pkg . '::EXPORT' }) {
                push @{ $EXPORTS{$caller} }, $keyword;
                *{ $class . '::' . $keyword } = *{ $pkg . '::' . $keyword };
            }

            if (my $exporter = $pkg->can('EXPORT')) {
                $exporter->($pkg, $caller);
            }
        }

        Mouse::Meta::Class->initialize($caller);

        my ($import, $unimport) = Mouse::Exporter->build_import_methods(
            exporting_package => $caller,
            also => "Mouse",
        );

        $caller->$import({ into => $caller });
        $caller->meta->superclasses(@super);

        push @{ $EXPORTS{$class} }, $unimport;
    }

    sub unimport {
        my $caller  = caller;

        for my $item (@{ $EXPORTS{$caller} || [] }) {
            if (ref $item eq 'CODE') {
                $caller->$item;
            }
            else {
                no strict 'refs';
                delete ${ $caller . '::' }{ $item };
            }
        }
    }
};

1;
