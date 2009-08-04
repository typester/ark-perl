package Ark::View::MT;
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
    default => '.mt',
);

has use_cache => (
    is      => 'rw',
    isa     => 'Bool',
    default => 1,
);

has cache => (
    is      => 'rw',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { {} },
);

has open_layer => (
    is      => 'rw',
    isa     => 'Str',
    default => ':utf8',
);

has macro => (
    is      => 'rw',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { {} },
);

has options => (
    is      => 'rw',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { {} },
);

has mt => (
    is      => 'rw',
    isa     => 'Text::MicroTemplate::Extended',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $c     = sub { $self->context };
        my $stash = sub { $self->context->stash };

        $self->ensure_class_loaded('Text::MicroTemplate::Extended');
        Text::MicroTemplate::Extended->new(
            package_name  => ref($self) . '::_MT',
            include_path  => $self->include_path,
            extension     => $self->extension,
            use_cache     => $self->use_cache,
            open_layer    => $self->open_layer,
            macro         => {
                raw_string => sub($) { Text::MicroTemplate::EncodedString->new($_[0]) },
                %{ $self->macro },
            },
            template_args => {
                c     => $c,
                s     => $stash,
                stash => $stash,
            },
            %{ $self->options }
        );
    },
);

sub template {
    my ($self, $template) = @_;
    $self->context->stash->{__view_mt_template} = $template;
    $self;
}

sub render {
    my $self     = shift;
    my $template = shift;

    $template ||= $self->context->stash->{__view_mt_template}
              || $self->context->request->action->reverse
                  or return;

    my $form_renderer = \&Ark::Form::render;
    no warnings 'redefine';
    local *Ark::Form::render = sub {
        Text::MicroTemplate::EncodedString->new( $form_renderer->(@_) );
    } if $form_renderer;

    $self->mt->render($template, @_);
}

sub process {
    my ($self, $c) = @_;
    $c->response->body( $self->render );
}

1;
