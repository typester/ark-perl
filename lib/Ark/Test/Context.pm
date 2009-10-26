package Ark::Test::Context;
use Any::Moose '::Role';

before process => sub {
    Ark::Test::context($_[0]);
};

no Any::Moose '::Role';

1;
