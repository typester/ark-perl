package Ark::Model::Adaptor;
use Ark 'Model';

has class => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has constructor => (
    is      => 'rw',
    isa     => 'Str',
    default => 'new',
);

has args => (
    is  => 'rw',
    isa => 'Ref',
);

has deref => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

no Ark;

sub ARK_DELEGATE {
    my ($self, $c) = @_;

    my $class       = $self->class;
    my $constructor = $self->constructor;

    my $instance;
    if ($self->deref && $self->args) {
        if (ref($self->args) eq 'HASH') {
            $instance = $class->$constructor(%{ $self->args });
        }
        elsif (ref($self->args) eq 'ARRAY') {
            $instance = $class->$constructor(@{ $self->args });
        }
        else {
            die "Couldn't dereference: " . ref($self->args);
        }
    }
    else {
        $instance = $class->$constructor($self->args);
    }

    $instance;
}

1;

