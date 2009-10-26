package Ark::Plugin;
use Any::Moose '::Role';
use Any::Moose '::Exporter';

do {
    my %EXPORTS;

    sub import {
        my ($class, $context) = @_;

        require utf8; utf8->import;

        my $caller = caller;
        any_moose('::Meta::Role')->initialize($caller);

        my ($import, $unimport) = any_moose('::Exporter')->build_import_methods(
            exporting_package => $caller,
            also => any_moose('::Role'),
        );
        $EXPORTS{$caller} = $unimport;

        $caller->$import({ into => $caller });

        no strict 'refs';
        *{ $caller . '::plugin_context' } = sub { $context };
        *{ $caller . '::method' } = sub {
            my ($self, $method) = @_;
            my $caller = caller;
            my $sub = $caller->can($method) or die qq/No such method "$method" on $caller/;

            return sub { $sub->($self, @_) };
        };
    }

    sub unimport {
        goto \&{ $EXPORTS{ scalar caller } };
    }
};

1;
