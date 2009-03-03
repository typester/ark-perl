package Ark::Logger;
use Mouse;
use utf8;

sub log {
    my ($self, $type, $msg, @args) = @_;
    print STDERR sprintf("[%s] ${msg}\n", $type, @args);
}

1;

