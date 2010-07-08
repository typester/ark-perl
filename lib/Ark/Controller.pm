package Ark::Controller;
use Any::Moose;
use Path::AttrRouter::Controller;

BEGIN {
    extends 'Path::AttrRouter::Controller';
}

no Any::Moose;

sub ACTION {
    my ($self, $action, $context, @args) = @_;
    $context->execute( $self, $action->name, @args );
}

__PACKAGE__->meta->make_immutable;
