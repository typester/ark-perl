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
    lazy    => 1,
    default => '.mt',
);

has use_cache => (
    is      => 'rw',
    isa     => 'Bool',
    lazy    => 1,
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
    lazy    => 1,
    default => ':utf8',
);

has options => (
    is      => 'rw',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { {} },
);

has mt => (
    is      => 'rw',
    isa     => 'Text::MicroTemplate',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->ensure_class_loaded('Text::MicroTemplate');
        Text::MicroTemplate->new(
            package_name => __PACKAGE__,
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

    my $renderer = $self->build_template($template . $self->extension);
    $renderer->($self->context, @_)->as_string;
}

sub build_template {
    my ($self, $template) = @_;

    # return cached entry
    if ($self->use_cache == 2) {
        if (my $e = $self->cache->{$template}) {
            return $e->[1];
        }
    }

    # iterate
    for my $path (@{ $self->include_path }) {
        my $filepath = $path . '/' . $template;
        if (my @st = stat $filepath) {
            if (my $e = $self->cache->{$template}) {
                return $e->[1] if $st[9] == $e->[0];
            }

            open my $fh, "<".$self->open_layer, $filepath
                or die qq/failed to open "$filepath": $!/;
            my $src = do { local $/; <$fh> };
            close $fh;

            $self->mt->parse($src);
            my $renderer = $self->build;

            $self->cache->{$template} = [ $st[9], $renderer ];
            return $renderer;
        }
    }
    die "could not find template file: $template";
}

sub build {
    my $self = shift;

    my $__mt   = $self->mt;
    my $__code = $self->mt->code;

    my $__from = sub {
        my $i = 0;
        while (my @c = caller(++$i)) {
            return "$c[1] at line $c[2]" if $c[0] ne __PACKAGE__;
        }
        '';
    }->();

    my $__expr = <<"...";
package $__mt->{package_name};
sub {
    my \$c = shift;
    my \$s = \$c->stash;
    local \$SIG{__WARN__} = sub { print STDERR \$__mt->_error(shift, 4, \$__from) };
    Text::MicroTemplate::encoded_string((
        $__code
    )->(\@_));
}
...

    my $__die_msg;
    {
        local $@;
        if (my $__builder = eval $__expr) {
            return $__builder;
        }
        $__die_msg = $__mt->_error($@, 4, $__from);
    }
    die $__die_msg;
}

sub process {
    my ($self, $c) = @_;
    $c->response->body( $self->render );
}

1;
