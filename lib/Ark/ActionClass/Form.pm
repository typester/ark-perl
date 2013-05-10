package Ark::ActionClass::Form;
use Mouse::Role;

use Ark::Form;

sub form { shift->{form} }

around ACTION => sub {
    my $orig = shift;

    my ($self, $action, $context, @args) = @_;
    my $form_class = $action->attributes->{Form}->[0];
    if ($form_class) {
        local $self->{form};
        $context->ensure_class_loaded($form_class);
        my $form = $form_class->new( $context->request, $context );

        $context->stash->{form} = $form;
        $self->{form}           = $form;
        $orig->(@_);
    }
    else {
        $orig->(@_);
    }
};

no Mouse::Role;

sub _parse_Form_attr {
    my ($self, $name, $value) = @_;
    return Form => $value;
}

1;


