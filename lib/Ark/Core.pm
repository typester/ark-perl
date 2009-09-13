package Ark::Core;
use Mouse;

use Ark::Context;
use Ark::Action;
use Ark::ActionContainer;
use Ark::Request;

use Exporter::AutoClean;
use Path::Class qw/file dir/;

extends 'Mouse::Object', 'Class::Data::Inheritable';

__PACKAGE__->mk_classdata($_)
    for qw/context configdata plugins _class_stash external_model_class/;

has handler => (
    is      => 'rw',
    isa     => 'CodeRef',
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
        $self->ensure_class_loaded($class);
        $class->new( log_level => $self->log_level );
    },
);

has log_level => (
    is      => 'rw',
    isa     => 'Str',
    default => sub {
        $ENV{ARK_DEBUG} ? 'debug' : 'error';
    },
);

has debug => (
    is      => 'rw',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
        shift->log_level eq 'debug';
    },
);

has components => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
);

has actions => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
);

has action_cache => (
    is      => 'rw',
    isa     => 'Object',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->path_to('action.cache');
    },
);

has dispatch_types => (
    is      => 'rw',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->ensure_class_loaded($_) for qw/Ark::DispatchType::Path
                                              Ark::DispatchType::Regex
                                              Ark::DispatchType::Chained/;
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

        # create application specific context class for mod_perl
        my $class = $self->class_wrapper(
            name => 'Context',
            base => 'Ark::Context',
        );
    },
);

has setup_finished => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

after setup => sub {
    my $self = shift;

    $self->log( debug => 'Setup finished' );
    $self->setup_finished(1);
};

has lazy_roles => (
    is      => 'rw',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { {} },
);

no Mouse;

sub EXPORT {
    my ($class, $target) = @_;

    my $load_plugins = $class->can('load_plugins');
    my $use_model    = $class->can('use_model');
    my $config       = $class->can('config');
    my $config_sub   = sub { $config->( $target, @_ ) };

    Exporter::AutoClean->export(
        $target,
        use_plugins => sub { $load_plugins->( $target, @_ ) },
        use_model   => sub { $use_model->( $target, @_ ) },
        config      => $config_sub,
        conf        => $config_sub, # backward compatibility
    );
}

sub config {
    my $class  = shift;
    my $config = @_ > 1 ? {@_} : $_[0];

    $class->configdata({}) unless $class->configdata;

    if ($config) {
        for my $key (keys %{ $config || {} }) {
            $class->configdata->{$key} = $config->{$key};
        }
    }

    $class->configdata;
}

sub class_wrapper {
    my $self = shift;
    my $args = @_ > 1 ? {@_} : $_[0];

    my $pkg = ref($self) || $self;

    $self->log( fatal => q["name" and "base" parameters are required] )
        unless $args->{name} and $args->{base};

    my $classname = "${pkg}::Ark::$args->{name}";
    return $classname
        if Mouse::is_class_loaded($classname) && $classname->isa($args->{base});

    eval qq{
        package ${classname};
        use Mouse;
        extends '$args->{base}';
        1;
    };
    die $@ if $@;

    for my $plugin (@{ $self->lazy_roles->{ $args->{name} } || [] }) {
        $plugin->meta->apply( $classname->meta )
            unless $classname->meta->does_role( $plugin );
    }

    $classname;
}

sub class_stash {
    my $self = shift;
    $self->_class_stash || $self->_class_stash({});
}

sub load_plugins {
    my ($class, @names) = @_;

    $class->plugins([]) unless $class->plugins;

    my @plugins =
        map { $_ =~ /^\+(.+)/ ? $1 : 'Ark::Plugin::' . $_ } grep {$_} @names;

    push @{ $class->plugins }, @plugins;
}

sub setup {
    my $self  = shift;
    my $class = ref($self) || $self;
    my $args  = @_ > 1 ? {@_} : $_[0];

    $self->setup_debug_mode if $self->debug;

    $self->setup_home;

    # setup components
    $self->ensure_class_loaded('Module::Pluggable::Object');

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

sub setup_store {
    my $self = shift;

    $self->setup unless $self->setup_finished;

    my $cache = $self->action_cache or die q[action_cache does not specified];
    $self->ensure_class_loaded('Storable');

    my $used_dispatch_types
        = [ grep { $_->used } @{ $self->dispatch_types } ];

    # decompile regexp action because storable doen't recognize compiled regexp
    my ($regex_type) = grep { $_->name eq 'Regex' } @{ $self->dispatch_types };
    if ($regex_type->used) {
        for my $compiled (@{ $regex_type->compiled }) {
            $compiled->{re} = "$compiled->{re}";
        }
    }

    for my $namespace (keys %{ $self->actions }) { # TODO: clone this
        my $container = $self->actions->{$namespace};
        for my $name (keys %{ $container->actions }) {
            my $action = $container->actions->{$name};
            $action->{controller} = ref $action->{controller};
        }
    }

    my $state = {
        dispatch_types => $used_dispatch_types,
        actions        => $self->actions,
    };

    Storable::store($state, $cache);
}

sub setup_retrieve {
    my $self = shift;

    my $cache = $self->action_cache or die q[action_cache does not specified];
    $self->ensure_class_loaded('Storable');

    my $state = eval { Storable::retrieve($cache) }
        or return;

    $self->ensure_class_loaded(ref $_) for @{ $state->{dispatch_types} || [] };
    $self->dispatch_types($state->{dispatch_types});
    $self->log( debug => $_ ) for grep {$_} map { $_->list } @{ $self->dispatch_types };

    $self->actions($state->{actions});

    $self->log( debug => 'Minimal setup finished');
    $self->setup_finished(1)
}

sub setup_minimal {
    my ($self, %option) = @_;

    $self->setup_debug_mode if $self->debug;

    $self->setup_home;
    $self->setup_plugins;

    # cache
    $self->action_cache( $self->path_to($option{action_cache}) )
        if $option{action_cache};

    $self->setup_retrieve;
    $self->setup_store unless $self->setup_finished;
}

sub setup_debug_mode {
    my $self = shift;
    return if $self->context_class->meta->does_role('Ark::Context::Debug');

    $self->ensure_class_loaded('Ark::Context::Debug');
    Ark::Context::Debug->meta->apply( $self->context_class->meta );
}

sub setup_home {
    my $self = shift;
    return if $self->config->{home};

    my $class = ref $self;
    (my $file = "${class}.pm") =~ s!::!/!g;

    if (my $path = $INC{$file}) {
        $path =~ s/$file$//;

        $path = dir($path);

        if (-d $path) {
            $path = $path->absolute;
            while ($path->dir_list(-1) =~ /^b?lib$/) {
                $path = $path->parent;
            }

            $self->config->{home} = $path;
        }
    }
}

sub setup_plugin {
    my ($self, $plugin) = @_;

    $self->ensure_class_loaded($plugin);

    if (my $target_context = $plugin->plugin_context) {
        if ($target_context eq 'Core') {
            $plugin->meta->apply( $self->meta )
                unless $self->meta->does_role($plugin);
        }
        else {
            push @{ $self->lazy_roles->{ $target_context } }, $plugin;
        }
        return;
    }
    $plugin->meta->apply( $self->context_class->meta )
        unless $self->context_class->meta->does_role($plugin);
}

sub setup_plugins {
    my $self = shift;

    for my $plugin (@{ $self->plugins || [] }) {
        $self->setup_plugin($plugin);
    }

    $self->setup_default_plugins;
}

sub setup_default_plugins {
    my $self = shift;

    my $encoding_filter_required  = 1;
    for my $role (@{ $self->context_class->meta->roles }) {
        $encoding_filter_required = 0 if $role->name =~ /::Encoding::/;
    }

    $self->setup_plugin('Ark::Plugin::Encoding::Unicode') if $encoding_filter_required;
}

sub setup_actions {
    my $self = shift;

    for my $component (values %{ $self->components }) {
        $self->register_actions( $component )
            if $component->isa('Ark::Controller');
    }

    if ($self->debug) {
        for my $type (@{ $self->dispatch_types }) {
            my $table = $type->list or next;

            $self->log( debug => "Loaded %s actions:\n%s", $type->name, $table->draw );
        }
    }
}

sub load_component {
    my ($self, $component) = @_;

    if ($self->components->{ $component }) {
        return $self->components->{ $component };
    }

    $self->ensure_class_loaded($component) or return;
    $component->isa('Ark::Component') or return;

    # merge config
    $component->config( $self->config->{ $component->component_name } );

    my $instance = $component->new( app => $self, %{ $component->config } );
    if ($instance->can('ARK_DELEGATE')) {
        $instance = $instance->ARK_DELEGATE($self);
    }

    $self->components->{ $component } = $instance;
}

sub component {
    my ($self, $name) = @_;
    return unless $name;

    if ($name =~ /^\+/) {
        $name =~ s/^\+//;
    }
    else {
        $name = ref($self) . '::' . $name;
    }

    $self->ensure_class_loaded($name);
    $self->components->{$name} ||= $self->load_component($name);
}

sub controller {
    my ($self, $name) = @_;
    return unless $name;
    $self->components('Controller::' . $name);
}

sub model {
    my ($self, $name) = @_;

    if (my $class = $self->external_model_class) {
        return $name ? $class->get($name) : $class;
    }

    return unless $name;
    $self->component('Model::' . $name);
}

sub view {
    my ($self, $name) = @_;
    return unless $name;
    $self->component('View::' . $name);
}

sub use_model {
    my ($self, $model_class) = @_;
    $self->ensure_class_loaded( $model_class );
    $self->external_model_class( $model_class );
    $model_class->initialize if $model_class->can('initialize');
}

sub register_actions {
    my ($self, $controller) = @_;
    my $controller_class = ref $controller || $controller;

    $controller->_method_cache([ @{$controller->_method_cache} ]);

    $self->ensure_class_loaded('Data::Util');
    while (my $attr = shift @{ $controller->_attr_cache || [] }) {
        my ($pkg, $method) = Data::Util::get_code_info($attr->[0]);
        push @{ $controller->_method_cache }, [$method, $attr->[1]];
    }

    for my $cache (@{ $controller->_method_cache || [] }) {
        my ($method, $attrs) = @$cache;
        $attrs = $self->parse_action_attrs( $controller, $method, @$attrs );

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

    my $container = $self->actions->{ $action->namespace }
        ||= Ark::ActionContainer->new( namespace => $action->namespace );
    $container->actions->{ $action->name } = $action;
}

sub parse_action_attrs {
    my ($self, $controller, $name, @attrs) = @_;

    my %parsed;
    for my $attr (@attrs) {
        if (my ($k, $v) = ( $attr =~ /^(.*?)(?:\(\s*(.+?)\s*\))?$/ )) {
            ( $v =~ s/^'(.*)'$/$1/ ) || ( $v =~ s/^"(.*)"/$1/ )
                if defined $v;

            my $initializer = "_parse_${k}_attr";
            if ($controller->can($initializer)) {
                ($k, $v) = $controller->$initializer($name, $v);
                push @{ $parsed{$k} }, $v;
            }
            else {
                # TODO logger & log invalid attributes
            }
        }
    }

    return \%parsed;
}

sub log {
    my $self = shift;

    unless (@_) {
        return $self->logger;
    }
    else {
        # keep backward compatibility
        $self->logger->log(@_);
    }
}

sub get_action {
    my ($self, $action, $namespace) = @_;
    return unless $action;

    $namespace ||= '';
    $namespace = '' if $namespace eq '/';

    my $container = $self->actions->{$namespace} or return;
    $container->actions->{ $action };
}

sub get_actions {
    my ($self, $action, $namespace) = @_;
    return () unless $action;
    grep { defined } map { $_->actions->{ $action } } $self->get_containers($namespace);
}

sub get_containers {
    my ($self, $namespace) = @_;
    $namespace ||= '';
    $namespace = '' if $namespace eq '/';

    my @containers;
    if (length $namespace) {
        do {
            my $container = $self->actions->{$namespace};
            push @containers, $container if $container;
        } while $namespace =~ s!/[^/]+$!!;
    }
    push @containers, $self->actions->{''} if $self->actions->{''};

    reverse @containers;
}

sub ensure_class_loaded {
    my ($self, $class) = @_;
    Mouse::load_class($class) unless Mouse::is_class_loaded($class);
}

sub path_to {
    my ($self, @path) = @_;

    die qq[Can't call path_to method before setup_home]
        unless $self->config->{home};

    my $path = dir( $self->config->{home}, @path );
    return $path if -d $path;
    return file($path);
}

sub handle_request {
    my ($self, $req) = @_;

    my $context = $self->context_class->new( app => $self, request => $req );
    $self->context($context)->process;
    $self->context(undef);

    if ( my $error = $context->error->[-1] ) {
        chomp $error;
        $self->log( error => 'Caught exception in engine "%s"', $error );

        unless ($self->debug) {
            my $res = $context->response;
            $res->status(500);
            $res->body('Internal Server Error');
        }
    }

    return $context->response;
}

sub psgi_handler {
    my $self = shift;

    my $engine = HTTP::Engine->new(
        interface => {
            module => 'PSGI',
            request_handler => $self->handler,
        }
    );

    return sub { $engine->run(@_) };
}

1;


