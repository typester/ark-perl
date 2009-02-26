package Ark::Core;
use Mouse;

use Ark::Context;
use Ark::Action;
use Ark::Request;
use Ark::DispatchType::Path;
use Ark::DispatchType::Regex;
use Ark::DispatchType::Chained;

use Data::Util;
use Module::Pluggable::Object;

extends 'Ark::Component', 'Class::Data::Inheritable';

__PACKAGE__->mk_classdata($_) for qw/config plugins/;
__PACKAGE__->config( {} );
__PACKAGE__->plugins( [] );

has handler => (
    is      => 'rw',
    isa     => 'CodeRef',
    lazy    => 1,
    default => sub {
        my $self = shift;
        sub {
            $self->handle_request(@_);
        };
    },
);

has logger_class => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub { 'Ark::Logger' },
);

has logger => (
    is      => 'rw',
    isa     => 'Object',
    lazy    => 1,
    default => sub {
        my $self  = shift;
        my $class = $self->logger_class;
        Mouse::load_class($class) unless Mouse::load_class($class);
        $class->new;
    },
);

has log_level => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub { 'error' },
);

has log_levels => (
    is      => 'rw',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub {
        {   debug => 4,
            info  => 3,
            warn  => 2,
            error => 1,
            fatal => 0,
        };
    },
);

has components => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
);

has dispatch_types => (
    is      => 'rw',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub {
        my $self = shift;
        [
            Ark::DispatchType::Path->new,
            Ark::DispatchType::Regex->new,
            Ark::DispatchType::Chained->new,
        ];
    },
);

has context_class => (
    is      => 'rw',
    isa     => 'Str',
    default => sub {
        my $self = shift;
        my $pkg  = ref($self);

        # create application specific context class for mod_perl
        my $class = "${pkg}::Context";
        eval qq{
            package ${class};
            use base 'Ark::Context';
            1;
        };
        die $@ if $@;

        $class;
    },
);

no Mouse;

sub load_plugins {
    my ($class, @names) = @_;

    my @plugins =
        map { $_ =~ /^\+(.+)/ ? $1 : 'Ark::Plugin::' . $_ } grep {$_} @names;

    $class->plugins(\@plugins);
}

sub setup {
    my $self  = shift;
    my $class = ref($self) || $self;
    my $args  = @_ > 1 ? {@_} : $_[0];

    # setup components
    my @paths = qw/::Controller ::View ::Model/;
    my $locator = Module::Pluggable::Object->new(
        search_path => [ map { $class . $_ } @paths ],
    );

    my @components = $locator->plugins;
    for my $component (@components) {
        $self->load_component($component);
    }

    $self->setup_plugins;
    $self->setup_actions;
}

sub setup_plugins {
    my $self = shift;

    for my $plugin (@{ $self->plugins }) {
        Mouse::load_class($plugin) unless Mouse::is_class_loaded($plugin);
        $plugin->meta->apply($self->context_class->meta);
    }
}

sub setup_actions {
    my $self = shift;

    for my $component (@{ $self->components }) {
        $self->register_actions( $component )
            if $component->isa('Ark::Controller');
    }

    $self->log( debug => $_ ) for grep {$_} map { $_->list } @{ $self->dispatch_types };
}

sub load_component {
    my ($self, $component) = @_;

    Mouse::load_class($component) unless Mouse::is_class_loaded($component);

    my $instance = $component->new( app => $self );
    $instance->apply_config( $self->config->{ $instance->component_name });
    push @{ $self->components }, $instance;
}

sub register_actions {
    my ($self, $controller) = @_;
    my $controller_class = ref $controller || $controller;

    while (my $attr = shift @{ $controller->_attr_cache || [] }) {
        my ($pkg, $method) = Data::Util::get_code_info($attr->[0]);
        $controller->_method_cache->{ $method } = $attr->[1];
    }

    for my $method (keys %{ $controller->_method_cache }) {
        my $attrs = $controller->_method_cache->{$method} or next;
        $attrs = $self->_parse_attrs( $controller, $method, @$attrs );

        my $ns      = $controller->namespace;
        my $reverse = $ns ? "$ns/$method" : $method;

        $self->register_action(Ark::Action->new(
            name       => $method,
            reverse    => $reverse,
            namespace  => $ns,
            attributes => $attrs,
            controller => $controller,
        ));
    }
}

sub register_action {
    my ($self, $action) = @_;

    for my $type (@{ $self->dispatch_types || [] }) {
        $type->register($action);
    }
}

sub _parse_attrs {
    my ($self, $controller, $name, @attrs) = @_;

    my %parsed;
    for my $attr (@attrs) {
        if (my ($k, $v) = ( $attr =~ /^(.*?)(?:\(\s*(.+?)\s*\))?$/ )) {
            ( $v =~ s/^'(.*)'$/$1/ ) || ( $v =~ s/^"(.*)"/$1/ )
                if defined $v;

            my $initializer = "_parse_${k}_attr";
            if ($self->can($initializer)) {
                ($k, $v) = $self->$initializer($controller, $name, $v);
                push @{ $parsed{$k} }, $v;
            }
            else {
                # TODO logger & log invalid attributes
            }
        }
    }

    return \%parsed;
}

sub _parse_Path_attr {
    my ($self, $controller, $name, $value) = @_;
    $value = '' unless defined $value;

    if ($value =~ m!^/!) {
        return Path => $value;
    }
    elsif (length $value) {
        return Path => join '/', $controller->namespace, $value;
    }
    else {
        return Path => $controller->namespace;
    }
}

sub _parse_Global_attr {
    my ($self, $controller, $name, $value) = @_;
    $self->_parse_Path_attr( $controller, $name, "/$name" );
}

sub _parse_Local_attr {
    my ($self, $controller, $name, $value) = @_;
    $self->_parse_Path_attr( $controller, $name, $name );
}

sub _parse_Args_attr {
    my ($self, $controller, $name, $value) = @_;
    return Args => $value;
}

sub _parse_Regex_attr {
    my ($self, $controller, $name, $value) = @_;
    return Regex => $value;
}

sub _parse_LocalRegex_attr {
    my ($self, $controller, $name, $value) = @_;

    unless ( $value =~ s/^\^// ) { $value = "(?:.*?)$value"; }

    my $prefix = $controller->namespace;
    $prefix .= '/' if length( $prefix );

    return ( 'Regex', "^${prefix}${value}" );
}

sub _parse_Chained_attr {
    my ($self, $controller, $name, $value) = @_;

    if (defined $value && length $value) {
        if ($value eq '.') {
            $value = '/' . $controller->namespace;
        }
        elsif (my ($rel, $rest) = $value =~ /^((?:\.{2}\/)+)(.*)$/) {
            my @parts  = split '/', $controller->namespace;
            my @levels = split '/', $rel;

            $value = '/' . join '/', @parts[0 .. $#parts - @levels], $rest;
        }
        elsif ($value !~ m!^/!) {
            my $action_ns = $controller->namespace;

            if ($action_ns) {
                $value = '/' . join '/', $action_ns, $value;
            }
            else {
                $value = '/' . $value;
            }
        }
    }
    else {
        $value = '/';
    }

    return Chained => $value;
}

sub _parse_CaptureArgs_attr {
    my ($self, $controller, $name, $value) = @_;
    return CaptureArgs => $value;
}

sub _parse_PathPart_attr {
    my ($self, $controller, $name, $value) = @_;
    return PathPart => $value;
}

sub log {
    my $self = shift;
    my ($type, $msg, @args) = @_;
    return if !$self->log_levels->{$type} or
        $self->log_levels->{$type} > $self->log_levels->{ $self->log_level };

    $self->logger->log(@_);
}

sub prepare_context {
    my ($self, $req) = @_;

    my $context = Ark::Context->new(
        app     => $self,
        request => $req,
    );

    my @path = split /\//, $req->path;
    unshift @path, '' unless @path;

 DESCEND: while (@path) {
        my $path = join '/', @path;
        $path =~ s!^/!!;

        for my $type (@{ $self->dispatch_types }) {
            last DESCEND if $type->match( $context->req, $path );
        }

        my $arg = pop @path;
        $arg =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
        unshift @{ $context->req->args }, $arg;
    }

    s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg
        for grep {defined} @{ $context->req->captures || [] };

    $self->log( debug => 'Path is "%s"', $context->req->match );
    $self->log( debug => 'Arguments are "%s"', join('/', @{ $context->req->args }) );

    $context;
}

sub handle_request {
    my ($self, $req) = @_;

    my $context = $self->context_class->new( app => $self, request => $req );

    $context->setup unless $context->setup_finished;
    $context->process;

    return $context->response;
}

1;

