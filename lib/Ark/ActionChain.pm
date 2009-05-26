package Ark::ActionChain;
use Mouse;

extends 'Ark::Action';

has chain => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
);

sub dispatch {
    my ($self, $context, @args) = @_;

    my $req = $context->request;

    my @captures = @{ $req->captures || [] };
    my @chain    = @{ $self->chain };
    my $last     = pop @chain;

    for my $action (@chain) {
        my @args;
        if (my $cap = $action->attributes->{CaptureArgs}) {
            @args = splice @captures, 0, $cap->[0];
        }
        local $req->{args} = \@args;
        $action->dispatch($context, @args);
    }
    $last->dispatch($context, @{ $req->args });
}

sub from_chain {
    my ($self, $actions) = @_;

    my $final = $actions->[-1];
    $self->new({ %$final, chain => $actions });
}

1;

