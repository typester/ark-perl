package Ark::Controller;
use Mouse;

extends 'Ark::Component', 'Class::Data::Inheritable';

__PACKAGE__->mk_classdata($_) for qw/_attr_cache _method_cache/;
__PACKAGE__->_attr_cache( [] );
__PACKAGE__->_method_cache( [] );

has namespace => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self  = shift;
        my $class = ref $self || $self;

        my ($ns) = $class =~ /::Controller::(.+)$/;
        $ns =~ s!::!/!g;
        $ns ||= '';
        lc $ns;
    },
);

no Mouse;

sub MODIFY_CODE_ATTRIBUTES {
    my ($class, $code, @attrs) = @_;

    $class->_attr_cache([ @{ $class->_attr_cache } ]);
    push @{ $class->_attr_cache }, [ $code, \@attrs ];
    return;
}

sub ACTION {
    my ($self, $action, @args) = @_;
    $self->context->execute( $self, $action->name, @args );
}

sub _parse_Path_attr {
    my ($self, $name, $value) = @_;
    $value = '' unless defined $value;

    if ($value =~ m!^/!) {
        return Path => $value;
    }
    elsif (length $value) {
        return Path => join '/', $self->namespace, $value;
    }
    else {
        return Path => $self->namespace;
    }
}

sub _parse_Global_attr {
    my ($self, $name, $value) = @_;
    $self->_parse_Path_attr( $name, "/$name" );
}

sub _parse_Local_attr {
    my ($self, $name, $value) = @_;
    $self->_parse_Path_attr( $name, $name );
}

sub _parse_Args_attr {
    my ($self, $name, $value) = @_;
    return Args => $value;
}

sub _parse_Regex_attr {
    my ($self, $name, $value) = @_;
    return Regex => $value;
}

sub _parse_LocalRegex_attr {
    my ($self, $name, $value) = @_;

    unless ( $value =~ s/^\^// ) { $value = "(?:.*?)$value"; }

    my $prefix = $self->namespace;
    $prefix .= '/' if length( $prefix );

    return ( 'Regex', "^${prefix}${value}" );
}

sub _parse_Chained_attr {
    my ($self, $name, $value) = @_;

    if (defined $value && length $value) {
        if ($value eq '.') {
            $value = '/' . $self->namespace;
        }
        elsif (my ($rel, $rest) = $value =~ /^((?:\.{2}\/)+)(.*)$/) {
            my @parts  = split '/', $self->namespace;
            my @levels = split '/', $rel;

            $value = '/' . join '/', @parts[0 .. $#parts - @levels], $rest;
        }
        elsif ($value !~ m!^/!) {
            my $action_ns = $self->namespace;

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
    my ($self, $name, $value) = @_;
    return CaptureArgs => $value;
}

sub _parse_PathPart_attr {
    my ($self, $name, $value) = @_;
    return PathPart => $value;
}

1;
