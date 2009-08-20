package Ark::Form;
use utf8;
use Mouse;

use Clone 'clone';
use Exporter::AutoClean;
use HTML::Shakan;
use HTML::Shakan::Utils;

extends 'Mouse::Object', 'Class::Data::Inheritable';

__PACKAGE__->mk_classdata('_fields_data');
__PACKAGE__->mk_classdata('_fields_data_order');
__PACKAGE__->mk_classdata('_fields_messages');
__PACKAGE__->mk_classdata('_widgets_class');

has _shakan => (
    is       => 'rw',
    isa      => 'HTML::Shakan',
    handles  => [
        qw/has_error load_function_message get_error_messages is_error is_valid
           set_error set_message/, # _shakan->_fvl
        qw/submitted submitted_and_valid fillin_param fillin_params request
          param params upload uploads widgets/, # _shakan
    ],
);

has 'id_tmpl' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'id_%s',
);

has context => (
    is       => 'rw',
    isa      => 'Ark::Context',
    weak_ref => 1,
);

has request => (
    is       => 'rw',
    isa      => 'Object',
    required => 1,
);

has fields => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub {
        my $self = shift;

        my $fields = {};

        for my $name (@{ $self->_fields_data_order }) {
            my %params = %{ clone $self->_fields_data->{ $name } };

            my $field;
            my $type = delete $params{type}
                or die 'type parameter is required';

            if (my $cv = delete $params{custom_validation}) {
                $params{custom_validation} = sub { $cv->($self, @_) };
            }

            if ($self->needs_localize) {
                if (my $label = delete $params{label}) {
                    $params{label} = $self->localize($label);
                }

                if (my $choices = delete $params{choices}) {
                    while (my ($v, $l) = splice @$choices, 0, 2) {
                        push @{ $params{choices} }, $v, $self->localize($l);
                    }
                }
            }

            if (my ($func) = grep { $type eq $_ } @HTML::Shakan::Fields::EXPORT) {
                $field = $self->can($func)->(%params);
            }
            else {
                $field = HTML::Shakan::Field::Input->new(
                    type => $type,
                    %params,
                );
            }

            $fields->{ $name } = $field;
        }

        $fields;
    },
);

no Mouse;

sub EXPORT {
    my ($class, $target) = @_;

    my %cloned;

    Exporter::AutoClean->export(
        $target,
        param   => sub {
            # XXX: fix this, need more clean param declation inheritance
            unless ($cloned{$target}++) {
                for my $cd (qw/_fields_messages _fields_data _fields_data_order/) {
                    Class::Data::Inheritable::mk_classdata(
                        $target, $cd, clone $class->$cd,
                    );
                }
            }
            $class->set_param_data(@_);
        },
        widgets => sub {
            $class->_widgets_class($_[0]);
        },
    );

    {
        no strict 'refs';
        *{"$target\::x"} = \&x;
    }
}

sub BUILDARGS {
    my ($self, $request, $context) = @_;

    return {
        request => $request,
        $context ? (context => $context) : (),
    };
}

sub BUILD {
    my $self = shift;

    my $fields = $self->fields;

    $self->_shakan( HTML::Shakan->new(
        request => $self->request,
        fields  => [map { $fields->{$_} } @{ $self->_fields_data_order }],
        $self->can('custom_validation')
            ? (custom_validation => sub { $self->custom_validation(@_) }) : (),
        $self->_widgets_class
            ? (widgets => $self->_widgets_class) : (),
    ));
}

sub field {
    my ($class, $name, $value) = @_;

    if ($value) {
        $class->fields->{ $name } = $value;
    }

    $class->fields->{ $name };
}

sub set_param_data {
    my ($self, $name, %params) = @_;

    my $overwrite = $name =~ s/^\+//;
    my $class     = caller(1);

    $params{name} = $name;

    $class->_fields_messages({}) unless $class->_fields_messages;
    if (my $messages = delete $params{messages}) {
        for my $func (keys %{ $messages || {} }) {
            my $message = $messages->{$func};
            $class->_fields_messages->{ "$name.$func" } = $message;
        }
    }

    $class->_fields_data({}) unless $class->_fields_data;
    if ($overwrite) {
        my $data = $class->_fields_data->{ $name }
            or die qq{param "$name" does not defined by parent class};

        while (my ($k, $v) = each %params) {
            $data->{ $k } = $v;
        }
    }
    else {
        $params{attr} ||= {};
        defined $params{$_} and $params{attr}{$_} ||= $params{$_} for qw/id name value/;

        $class->_fields_data->{ $name } = \%params;
    }

    $class->_fields_data_order([]) unless $class->_fields_data_order;
    push @{ $class->_fields_data_order }, $name
        unless grep { $_ eq $name } @{ $class->_fields_data_order };
}

sub label {
    my ($self, $name) = @_;

    my $field = $self->field($name) or return;
    my $label = $field->label or return;

    unless ($field->id) {
        $field->id(sprintf($self->id_tmpl, $name));
    }

    sprintf q{<label for="%s">%s</label>},
        encode_entities($field->id), encode_entities($label);
}

sub input {
    my ($self, $name) = @_;

    my $field = $self->field($name) or return;
    $self->widgets->render( $self->_shakan, $field );
}

sub render {
    my ($self, $name) = @_;
    return $self->_shakan->render unless $name;

    my $res = ($self->label($name) || '')
            . ($self->input($name) || '')
            . ($self->error_message($name) || '');
}

sub valid_param {
    my ($self, $name) = @_;
    return if $self->is_error($name);
    return $self->param($name);
}

sub ignore_error {
    my ($self, $form, $name) = @_;

    delete $form->_fvl->{_error}{ $name };
    @{ $form->_fvl->{_error_ary} } =
        grep { $_->[0] ne $name } @{ $form->_fvl->{_error_ary} };
}

sub needs_localize {
    my $self = shift;
    $self->context && $self->context->can('localize');
}

sub localize {
    my $self = shift;
    return '' if $_[0] eq '';
    $self->needs_localize && $self->context->localize(@_);
}

sub error_message_plain {
    my ($self, $name) = @_;
    return unless $self->submitted && $self->is_error($name);

    my ($error) =
        grep { $_->[0] eq $name } @{ $self->_shakan->_fvl->{_error_ary} || [] }
            or return;

    $self->_create_error_message($name, lc $error->[1]);
}

sub error_messages_plain {
    my ($self, $name) = @_;
    return unless $self->submitted && $self->is_error($name);

    my (@errors) =
        grep { $_->[0] eq $name } @{ $self->_shakan->_fvl->{_error_ary} || [] }
            or return;

    [map { $self->_create_error_message($name, lc $_->[1]) } @errors];
}

sub _create_error_message {
    my ($self, $name, $func) = @_;

    my $field = $self->field($name);
    my $label = $field ? $field->label || $field->name : $func;

    my $messages = {
        %{ $self->messages || {} },
        %{ $self->_fields_messages || {} },
    };

    my $message = $messages->{"$name.$func"}
               || $messages->{ $func };

    unless ($message) {
        warn qq{Message "$name.$func" does not defined};
        return;
    }

    if ($self->needs_localize) {
        $label   = $self->localize( $label );
        $message = $self->localize( $message, $label );
    }
    else {
        my $gen_msg = sub {
            my ($tmpl, @args) = @_;
            local $_ = $tmpl;
            s!\[_(\d+)\]!$args[$1-1]!ge;
            $_;
        };
        $message = $gen_msg->( $message, $label );
    }

    $message;
}

sub error_message {
    my ($self, $name) = @_;
    sprintf($self->message_format, $self->error_message_plain($name) || return);
}

sub error_messages {
    my ($self, $name) = @_;
    [ map { sprintf( $self->message_format, $_ ) }
            @{ $self->error_messages_plain($name) || [] } ];
}

sub fill {
    my $self = shift;
    my $p    = @_ > 1 ? {@_} : $_[0];

    for my $k (keys %$p) {
        $self->fillin_params->{ $k } = $p->{ $k };
    }
}

sub x { $_[0] };

sub messages {
    my $self = shift;

    return {
        not_null => '[_1] is required',
        map({ $_ => '[_1] is invalid' } qw/
                int ascii date duplication length regex uint
                http_url
                email_loose
                hiragana jtel jzip katakana
                file_size file_mime
                / ),
        %{ $self->_fields_messages },
    };
}

sub message_format {
    '<span class="error">%s</span>';
}

1;
