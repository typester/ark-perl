package Ark::Models;
use strict;
use warnings;
use base 'Object::Container';

sub import {
    my $pkg  = shift;
    my $flag = shift || 'model';

    unshift @_, $pkg, $flag;
    goto $pkg->can('SUPER::import');
}

1;
