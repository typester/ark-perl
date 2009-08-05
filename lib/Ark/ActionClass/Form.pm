package Ark::ActionClass::Form;
use Mouse::Role;

use Ark::Form;

has form => (
    is  => 'rw',
    isa => 'Ark::Form',
);

before ACTION => sub {
    my ($self, $action, @args) = @_;
    my $form_class = $action->attributes->{Form}->[0] or return;

    $self->ensure_class_loaded($form_class);
    my $form = $form_class->new( $self->context->request, $self->context );

    $self->form( $form );
    $self->context->stash->{form} = $form;
};

no Mouse::Role;

sub _parse_Form_attr {
    my ($self, $name, $value) = @_;
    return Form => $value;
}

1;

