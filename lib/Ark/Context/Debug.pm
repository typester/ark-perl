package Ark::Context::Debug;
use Mouse::Role;

has debug_report => (
    is      => 'rw',
    isa     => 'Text::SimpleTable',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->ensure_class_loaded('Text::SimpleTable');
        Text::SimpleTable->new([62, 'Action'], [9, 'Time']);
    },
);

has debug_report_stack => (
    is      => 'rw',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub { [] },
);

around process => sub {
    my $next = shift;
    my ($self,) = @_;

    $self->ensure_class_loaded('Time::HiRes');
    my $start = [Time::HiRes::gettimeofday()];

    my $res = $next->(@_);

    my $elapsed = sprintf '%f', Time::HiRes::tv_interval($start);
    my $av      = $elapsed == 0 ? '??' : sprintf '%.3f', 1 / $elapsed;
    $self->log( debug =>
                  "Request took ${elapsed}s (${av}/s)\n%s", $self->debug_report->draw);

    $res;
};

after prepare_action => sub {
    my $self = shift;
    my $req  = $self->request;

    $self->log( debug => q/"%s" request for "%s" from "%s"/,
                $req->method, $req->path, $req->address );
    $self->log( debug => q/Arguments are "%s"/, join('/', @{ $req->arguments }) );
};

around execute_action => sub {
    my $next = shift;
    my ($self, $obj, $method, @args) = @_;

    $self->ensure_class_loaded('Time::HiRes');
    $self->stack->[-1]->{start} = [Time::HiRes::gettimeofday()];

    my $res = $next->(@_);

    my $last    = $self->stack->[-1];
    my $elapsed = Time::HiRes::tv_interval($last->{start});

    my $name;
    if ($last->{obj}->isa('Ark::Controller')) {
        $name = $last->{obj}->namespace
            ? '/' . $last->{obj}->namespace . '/' . $last->{method}
            : '/' . $last->{method};
    }
    else {
        $name = $last->{as_string};
    }

    if ($self->depth > 1) {
        $name = ' ' x $self->depth . '-> ' . $name;
        push @{ $self->debug_report_stack }, [ $name, sprintf("%fs", $elapsed) ];
    }
    else {
        $self->debug_report->row( $name, sprintf("%fs", $elapsed) );
        while (my $report = pop @{ $self->debug_report_stack }) {
            $self->debug_report->row( @$report );
        }
    }

    $res;
};

1;

