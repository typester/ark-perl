package Ark::Core;
use Mouse;

use Ark::Action;
use Ark::Request;
use Ark::DispatchType::Path;
use Ark::DispatchType::Regex;
use Ark::DispatchType::Chained;

use Data::Util;
use Module::Pluggable::Object;

extends 'Ark::Component', 'Class::Data::Inheritable';

__PACKAGE__->mk_classdata($_) for qw/config/;
__PACKAGE__->config( {} );

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

no Mouse;

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

    $self->setup_actions;
}

sub setup_actions {
    my $self = shift;

    for my $component (@{ $self->components }) {
        $self->register_actions( $component )
            if $component->isa('Ark::Controller');
    }

    warn $_ for grep {$_} map { $_->list } @{ $self->dispatch_types };
}

sub load_component {
    my ($self, $component) = @_;

    Mouse::load_class($component) unless Mouse::is_class_loaded($component);

    my $instance = $component->new( context => $self );
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

sub handle_request {
    my ($self, $req) = @_;
    $req = Ark::Request->new({ %$req });

    $req->context($self);
    $req->prepare_action;

    if (my $action = $req->action) {
        $action->dispatch($req);
    }
    else {
        warn 'no action found';
    }
}

1;

