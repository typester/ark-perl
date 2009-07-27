package Ark::Form;
use utf8;
use Mouse;

use Exporter::AutoClean;
use HTML::Shakan;
use HTML::Shakan::Utils;

extends 'Mouse::Object', 'Class::Data::Inheritable';

__PACKAGE__->mk_classdata('_fields_data');
__PACKAGE__->mk_classdata('_fields_data_order');

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
    isa      => 'HTTP::Engine::Request',
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
            my %params = %{ $self->_fields_data->{ $name } };

            my $field;
            my $type = delete $params{type}
                or die 'type parameter is required';

            my $constraints = delete $params{constraints};
            if (my $cv = delete $params{custom_validation}) {
                $params{custom_validation} = sub { $cv->($self, @_) };
            }

            my %attr = map { $_ => $params{$_} }
                      grep { not ref( $params{$_} ) } keys %params;

            if (my ($func) = grep { $type eq $_ } @HTML::Shakan::Fields::EXPORT) {
                $field = $self->can($func)->(
                    %params,
                    attr => \%attr,
                );
            }
            else {
                $field = HTML::Shakan::Field::Input->new(
                    %params,
                    attr => \%attr,
                );
            }

            $field->add_constraint($_) for @{ $constraints || [] };

            $fields->{ $name } = $field;
        }

        $fields;
    },
);

no Mouse;

sub EXPORT {
    my ($class, $target) = @_;

    Exporter::AutoClean->export(
        $target,
        param => sub { $class->set_param_data(@_) },
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
        context => $context || undef,
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

    $params{name} = $name;

    $self->_fields_data({}) unless $self->_fields_data;
    $self->_fields_data->{ $name } = \%params;

    $self->_fields_data_order([]) unless $self->_fields_data_order;
    push @{ $self->_fields_data_order }, $name;
}

sub label {
    my ($self, $name) = @_;

    my $field = $self->field($name) or return;
    unless ($field->id) {
        $field->id(sprintf($self->id_tmpl, $name));
    }

    my $label = $field->label || $field->name;
    if ($self->context and $self->context->can('localize')) {
        $label = $self->context->localize($label);
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

sub needs_localize {
    my $self = shift;
    $self->context && $self->context->can('localize');
}

sub localize {
    my $self = shift;
    $self->needs_localize && $self->context->localize(@_);
}

sub error_message {
    my ($self, $name) = @_;
    return unless $self->submitted && $self->has_error;

    my (@errors) =
        grep { $_->[0] eq $name } @{ $self->_shakan->_fvl->{_error_ary} || [] }
            or return;

    # I18N
    my $error = $errors[0];
    my $func  = lc $error->[1];

    my $field = $self->field($name);
    my $label = $field ? $field->label || $field->name : $func;

    my $message = $self->messages->{"$name.$func"} # "param.function"
               || $self->messages->{$func};        # "function"

    unless ($message) {
        warn qq{Message "$name.$func" does not defined};
        return;
    }

    if ($self->needs_localize) {
        $label   = $self->localize( $label );
        $message = $self->localize( $message, $label );
    }

    if (my $fmt = $self->message_format) {
        $message = sprintf($fmt, $message);
    }

    $message;
}

sub x { $_[0] };

sub messages {
    my $self = shift;

    if ($self->needs_localize) {
        return {
            not_null => x('please input [_1]', '$form'),
            int      => x('please input [_1] as integer', '$form'),
            http_url => x('please input [_1] as url', '$form'),
        };
    }
    else {
        return {
            not_null => 'please input',
            int      => 'please input as integer',
            http_url => 'please input as url',
        };
    }
}

sub message_format {
    '<span class="error">%s</span>';
}

1;
