package Ark;
use 5.008001;
use Mouse;

our $VERSION = '0.001000_002';

sub import {
    my $class  = shift;
    my @target = @_;

    require strict; strict->import;
    require warnings; warnings->import;
    require utf8; utf8->import;

    my $caller = caller;

    {
        no strict 'refs';

        my @super;
        push @target, 'Core' unless @target;
        for my $target (@target) {
            my $pkg;
            if ($target =~ /^\+/) {
                ($pkg = $target) =~ s/^\+//;
            }
            else {
                $pkg = "Ark::${target}";
            }
            push @super, $pkg;
            Mouse::load_class($pkg) unless Mouse::is_class_loaded($pkg);

            for my $keyword (@{$pkg . '::EXPORT'}) {
                *{ $caller . '::' . $keyword } = *{ $pkg . '::' . $keyword };
            }

            if (my $exporter = $pkg->can('EXPORT')) {
                $exporter->($pkg, $caller);
            }
        }

        for my $keyword (@Mouse::EXPORT) {
            *{ $caller . '::' . $keyword } = *{ 'Mouse::' . $keyword };
        }

        my $meta = Mouse::Meta::Class->initialize($caller);
        $meta->superclasses(@super);
        *{ $caller . '::meta' } = sub { $meta };
    }
}

sub unimport {
    my $caller = caller;

    no strict 'refs';
    for my $keyword (@Mouse::EXPORT) {
        delete ${ $caller . '::' }{$keyword};
    }
}

1;
