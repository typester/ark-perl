package Ark::Plugin::FormValidator::Lite;

use Ark::Plugin;
use FormValidator::Lite;

has validator => (
    is      => 'ro',
    isa     => 'FormValidator::Lite',
    lazy    => 1,
    default => sub {
        my ($c) = @_;
        FormValidator::Lite->load_constraints(qw/Japanese/);
        FormValidator::Lite->new( $c->request );
    },
);

1;
