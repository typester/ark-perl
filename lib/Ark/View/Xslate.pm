package Ark::View::Xslate;
use Ark 'View';

has path => (
    is      => 'rw',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub {
        my $self = shift;
        [$self->path_to('root')];
    },
);

has options => (
    is      => 'rw',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { {} },
);

has extension => (
    is      => 'rw',
    isa     => 'Str',
    default => '.tx',
);

has xslate => (
    is      => 'rw',
    isa     => 'Text::Xslate',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $c     = sub { $self->context };
        my $stash = sub { $self->context->stash };

        $self->ensure_class_loaded('Text::Xslate');
        Text::Xslate->new(
            path => $self->path,
            %{ $self->options }
        );
    },
);

sub template {
    my ($self, $template) = @_;
    $self->context->stash->{__view_xslate_template} = $template;
    $self;
}

sub render {
    my $self     = shift;
    my $template = shift;
    my $context  = $self->context;

    $template ||= $self->context->stash->{__view_xslate_template}
              || $self->context->request->action->reverse
                  or return;

    $self->xslate->render(
        $template . $self->extension,
        {
            %{ $context->stash },
            c => $self->context,
            @_,
        },
    );
}

sub process {
    my ($self, $c) = @_;
    $c->response->body( $self->render );
}

__PACKAGE__->meta->make_immutable;
