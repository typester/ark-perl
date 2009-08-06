package Ark::View::JSON;
use Ark 'View';

has allow_callback => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

has callback_param => (
    is      => 'rw',
    isa     => 'Str',
    default => 'callback',
);

has expose_stash => (
    is => 'rw',
);

has json_driver => (
    is      => 'rw',
    isa     => 'Object',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->ensure_class_loaded('JSON::Any');
        JSON::Any->import;

        JSON::Any->new(
            utf8         => 1,
            allow_nonref => 1,
        );
    },
);

has json_dumper => (
    is      => 'rw',
    isa     => 'CodeRef',
    lazy    => 1,
    default => sub {
        my $self = shift;
        sub { $self->json_driver->encode(@_) };
    },
);

# steel code from Catalyst::View::JSON
sub process {
    my ($self, $c) = @_;

    # get the response data from stash
    my $cond = sub { 1 };

    my $single_key;
    if (my $expose = $self->expose_stash) {
        if (ref($expose) eq 'Regexp') {
            $cond = sub { $_[0] =~ $expose };
        } elsif (ref($expose) eq 'ARRAY') {
            my %match = map { $_ => 1 } @$expose;
            $cond = sub { $match{$_[0]} };
        } elsif (!ref($expose)) {
            $single_key = $expose;
        } else {
            $c->log( warn => "expose_stash should be an array referernce or Regexp object.");
        }
    }

    my $data;
    if ($single_key) {
        $data = $c->stash->{$single_key};
    } else {
        $data = { map { $cond->($_) ? ($_ => $c->stash->{$_}) : () }
                  keys %{$c->stash} };
    }

    my $cb_param = $self->allow_callback
        ? ($self->callback_param || 'callback') : undef;
    my $cb = $cb_param ? $c->req->param($cb_param) : undef;
    $self->validate_callback_param($cb) if $cb;

    my $json = $self->json_dumper->($data);

    if (($c->req->user_agent || '') =~ /Opera/) {
        $c->res->content_type('application/x-javascript; charset=utf-8');
    } else {
        $c->res->content_type('application/json; charset=utf-8');
    }

    my $output;

    ## add UTF-8 BOM if the client is Safari ### XXXX
    if (($c->req->user_agent || '') =~ m/Safari/) {
        $output = "\xEF\xBB\xBF";
    }

    $output .= "$cb(" if $cb;
    $output .= $json;
    $output .= ");"   if $cb;

    $c->res->output($output);
}

1;

