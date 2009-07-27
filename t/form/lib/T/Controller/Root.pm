package T::Controller::Root;
use Ark 'Controller::Form';

has '+namespace' => default => '';

sub login_form_input :Local :Form('T::Form::Login') {
    my ($self, $c) = @_;

    $c->res->body( $self->form->input('username') );
}

sub login_form_render :Local :Form('T::Form::Login') {
    my ($self, $c) = @_;

    $c->res->body( $self->form->render('username') );
}

sub login :Local :Args(0) :Form('T::Form::Login') {
    my ($self, $c) = @_;
    $c->stash->{form} = $self->form;
}

1;

