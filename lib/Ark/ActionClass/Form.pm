package Ark::ActionClass::Form;
use Mouse::Role;

use Ark::Form;

has form => (
    is  => 'rw',
    isa => 'Ark::Form',
);

before ACTION => sub {
    my ($self, $action, $context, @args) = @_;
    my $form_class = $action->attributes->{Form}->[0] or return;

    $context->ensure_class_loaded($form_class);
    my $form = $form_class->new( $context->request, $context );

    $self->form( $form );
    $context->stash->{form} = $form;
};

no Mouse::Role;

sub _parse_Form_attr {
    my ($self, $name, $value) = @_;
    return Form => $value;
}

1;


