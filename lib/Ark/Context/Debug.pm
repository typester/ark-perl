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

has debug_stack_traces => (
    is      => 'rw',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub { [] },
);

has debug_screen_tamplate => (
    is      => 'rw',
    isa     => 'CodeRef',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->ensure_class_loaded('Text::MicroTemplate');
        Text::MicroTemplate::build_mt(<<'__EOF__');
? sub encoded_string { goto &Text::MicroTemplate::encoded_string }
<?= encoded_string(qq[<\?xml version="1.0" encoding="utf-8"?\>\n]) ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="ja">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta http-equiv="Content-Script-Type" content="text/javascript" />
<title>500 Internal Server Error</title>
<style type="text/css">
* {
  margin: 0;
  padding: 0;
  font-family: Verdana, Arial, sans-serif;
  font-size: 100%;
}

pre {
  padding: 5px;
  overflow: auto;
}
code {
  font-family: Monaco, 'Courier New', monospace;
}

pre code {
  width: 100%;
}

body {
  font-size: 76%;
  background-color: #ccc;
}

#container {
  margin: 0 100px;
  padding: 30px;
  border-right: 1px solid;
  border-left: 1px solid;
  background-color: #fefefe;
}

h1 {
  color: #f00;
  font-size: 2em;
}

h2 {
  color: #006088;
  margin-top: 20px;
  font-size: 1.8em;
}

#error {
  padding: 10px;
  color: #f00;
  font-weight: bold;
  border: 1px solid #f00;
  background-color: #fee;
}

.dump pre {
  border: 1px solid #333;
  background-color: #ddd;
  width: 100%;
  overflow: auto;
  padding: 0px;
}

.dump pre code {
  display: block;
  padding: 10px;
  width: auto;
}

#stacktrace pre {
  border: none;
  padding: 0px;
}

.trace {
  border: 1px solid #333;
  background-color: #ddd;
  padding: 10px;
  margin-bottom: 5px;
}

.trace h3 {
  margin-bottom: 5px;
}

</style>
</head>

<body>
<div id="container">
<h1>500 Internal Server Error</h1>

<div id="error">
<pre><?= join "\n", @{ $_[0]->error } ?></pre>
</div>

<div id="stacktrace">
<h2>StackTrace</h2>
? for my $frame (@{ $_[0]->debug_stack_traces }) {
?     last if $frame->package =~ /^HTTP::Engine::Role::Interface/;
<div class="trace">
<h3><?= $frame->package ?> - line:<?= $frame->line ?></h3>
<pre><code><?= encoded_string( $_[0]->debug_print_context( $frame->filename, $frame->line, 3 ) ) ?>
</code></pre>
</div>
? }
</div>

</div>
</body>
</html>
__EOF__
    },
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

    if (my @error = @{ $self->error }) {
        $self->ensure_class_loaded('Text::MicroTemplate');

        $self->res->status(500);
        $self->res->body( $self->debug_screen_tamplate->($self)->as_string );
    }

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

    local $SIG{__DIE__} = sub {
        $self->ensure_class_loaded('Devel::StackTrace');
        my $trace = Devel::StackTrace->new(
            ignore_package => [
                qw/Ark::Core
                   Ark::Action
                   Ark::Context::Debug
                   Ark::Context/,
            ],
            no_refs => 1,
        );
        $self->debug_stack_traces([ $trace->frames ]);
    };

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
        while (my $report = shift @{ $self->debug_report_stack }) {
            $self->debug_report->row( @$report );
        }

        if (my @error = @{ $self->error }) {
            $self->res->status(500);
            my $body = $self->debug_screen_tamplate->($self)->as_string;
            $self->res->body( $body . ' 'x300 ) # for IE
        }
    }

    $res;
};

sub debug_print_context {
    my ($self, $file, $linenum, $context) = @_;

    my $code = q[];
    if (-f $file) {
        $self->ensure_class_loaded('HTML::Entities');

        my $start = $linenum - $context;
        my $end   = $linenum + $context;
        $start = $start < 1 ? 1 : $start;
        if ( my $fh = IO::File->new( $file, 'r' ) ) {
            my $cur_line = 0;
            while ( my $line = <$fh> ) {
                ++$cur_line;
                last if $cur_line > $end;
                next if $cur_line < $start;
                my @tag = $cur_line == $linenum ? qw(<strong> </strong>) : ( q{}, q{} );
                $code .= sprintf( '%s%5d: %s%s',
                    $tag[0], $cur_line, $line ? HTML::Entities::encode_entities($line) : q{},
                    $tag[1], );
            }
        }
    }
    return $code;
}

1;

