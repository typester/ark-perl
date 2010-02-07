package Ark::Plugin::MobileAgent;
use Ark::Plugin;

use HTTP::MobileAgent;

has mobile_agent => (
    is      => 'ro',
    isa     => 'HTTP::MobileAgent',
    lazy    => 1,
    default => sub {
        my ($c) = @_;
        HTTP::MobileAgent->new($c->req->headers);
    },
);

1;

