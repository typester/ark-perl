package Ark::Models;
use strict;
use warnings;
use base 'Object::Container';

sub import {
    my $pkg    = shift;
    my $export = shift || 'model';

    my $caller = caller;
    {
        no strict 'refs';
        *{"${caller}::${export}"} = sub {
            my ($model) = @_;
            return $model ? $pkg->get($model) : $pkg;
        };
    }
}

1;
