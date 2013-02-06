package Ark::Action;
use Mouse;

extends 'Path::AttrRouter::Action';

no Mouse;

sub dispatch {
    my ($self, $c, @args) = @_;
    return if $c->detached;

    $self->controller->ACTION( $self, $c, @args );
}

__PACKAGE__->meta->make_immutable;

