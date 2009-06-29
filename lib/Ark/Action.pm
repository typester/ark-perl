package Ark::Action;
use Mouse;

has [qw/namespace reverse name/] => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has attributes => (
    is       => 'rw',
    isa      => 'HashRef',
    required => 1,
);

has controller => (
    is       => 'rw',
    isa      => 'Ark::Controller | Str',
    required => 1,
);

no Mouse;

sub match {
    my ($self, $req) = @_;

    return 1 unless exists $self->attributes->{Args};

    my $args = $self->attributes->{Args}[0];
    return 1 unless defined($args) && length($args);
    return scalar( @{ $req->args } ) == $args;
}

sub dispatch {
    my ($self, $context, @args) = @_;

    return if $context->detached;

    my $req = $context->request;

    @args = @{ $req->args }
        or @args = @{ $req->captures }
            unless @args;

    # recreate controller instance if it is cached object
    unless (ref $self->{controller}) {
        $self->controller( $context->app->load_component($self->{controller}) );
    }

    $context->execute( $self->controller, $self->name, @args );
}

sub dispatch_chain {
    my ($self, $context) = @_;

    $self->dispatch_begin($context)
        and $self->dispatch_auto($context)
        and $self->dispatch($context);

    $context->detached(0);
    $self->dispatch_end($context);
}

sub dispatch_begin {
    my ($self, $context) = @_;

    my $action = ($context->get_actions('begin', $self->namespace))[-1]
        or return 1;

    $action->dispatch($context);
    return !@{ $context->error };
}

sub dispatch_auto {
    my ($self, $context) = @_;

    for my $action ($context->get_actions('auto', $self->namespace)) {
        $action->dispatch($context);
        return 0 unless $context->state;
    }

    1;
}

sub dispatch_end {
    my ($self, $context) = @_;

    my $action = ($context->get_actions('end', $self->namespace))[-1]
        or return 1;

    $action->dispatch($context);
    return !@{ $context->error };
}

1;

