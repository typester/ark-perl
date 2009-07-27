package Ark::Test::Context;
use Mouse::Role;

before process => sub {
    Ark::Test::context($_[0]);
};

no Mouse::Role;

1;
