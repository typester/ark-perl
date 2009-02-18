package Ark::Logger;
use Mouse;

sub log {
    my ($self, $type, $msg, @args) = @_;
    print STDERR sprintf("[%s] ${msg}\n", $type, @args);
}

1;

