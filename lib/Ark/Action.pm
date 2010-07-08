package Ark::Action;
use Any::Moose;

extends 'Path::AttrRouter::Action';

no Any::Moose;

sub dispatch {
    my ($self, $c, @args) = @_;
    return if $c->detached;

    $self->controller->ACTION( $self, $c, @args );
}

__PACKAGE__->meta->make_immutable;

