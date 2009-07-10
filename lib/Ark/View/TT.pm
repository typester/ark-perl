package Ark::View::TT;
use Ark 'View';

has include_path => (
    is      => 'rw',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub {
        my $self = shift;
        [$self->path_to('root')];
    },
);

has extension => (
    is      => 'rw',
    isa     => 'Str',
    default => '.tt',
);

has options => (
    is      => 'rw',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { {} },
);

has tt => (
    is      => 'rw',
    isa     => 'Template',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $c     = sub { $self->context };
        my $stash = sub { $self->context->stash };

        $self->ensure_class_loaded('Template');
        Template->new(
            INCLUDE_PATH => $self->include_path,
            ENCODING     => 'utf8',
            %{ $self->options }
        );
    },
);

sub template {
    my ($self, $template) = @_;
    $self->context->stash->{__view_tt_template} = $template;
    $self;
}

sub render {
    my $self     = shift;
    my $template = shift;
    my $context  = $self->context;

    $template ||= $self->context->stash->{__view_tt_template}
              || $self->context->request->action->reverse
                  or return;

    $self->tt->process(
        $template . $self->extension,
        {
            %{ $context->stash },
            c => $self->context,
            @_,
        },
        \my $output,
    );

    $output;
}

sub process {
    my ($self, $c) = @_;
    $c->response->body( $self->render );
}

1;
