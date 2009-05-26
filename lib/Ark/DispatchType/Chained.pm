package Ark::DispatchType::Chained;
use Mouse;

use Ark::ActionChain;

has name => (
    is      => 'rw',
    isa     => 'Str',
    default => 'Chained',
);

has children_of => (
    is      => 'rw',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { {} },
);

has actions => (
    is      => 'rw',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { {} },
);

has endpoints => (
    is      => 'rw',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub { [] },
);

has list => (
    is      => 'rw',
    isa     => 'Text::SimpleTable | Undef',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return unless $self->used;

        eval "require Text::SimpleTable"; die $@ if $@;
        my $paths = Text::SimpleTable->new([ 35, 'Path Spec' ], [ 36, 'Private' ]);

        my @endpoints = sort { $a->reverse cmp $b->reverse } @{$self->endpoints};
    ENDPOINT: for my $endpoint (@endpoints) {
            my $args = $endpoint->attributes->{Args}->[0];
            my @parts = defined $args ? '*' x $args : '...';

            my @parents;
            my $parent = 'DUMMY';
            my $cur    = $endpoint;
            while ($cur) {
                if (my $cap = $cur->attributes->{CaptureArgs}) {
                    unshift @parts, '*' x $cap->[0];
                }
                if (my $pp = $cur->attributes->{PathPart}) {
                    unshift @parts, $pp->[0]
                        if defined $pp->[0] && length $pp->[0];
                }
                $parent = $cur->attributes->{Chained}[0];
                $cur = $self->actions->{$parent};
                unshift @parents, $cur if $cur;
            }
            next ENDPOINT unless $parent eq '/';

            my @rows;
            for my $p (@parents) {
                my $name = "/$p->{reverse}";
                if (my $cap = $p->attributes->{CaptureArgs}) {
                    $name .= ' (' . $cap->[0] . ')';
                }
                unless ($p eq $parents[0]) {
                    $name = "-> ${name}";
                }
                push @rows, [ '', $name ];
            }
            push @rows, [ '', (@rows ? '=> ' : '') . "/$endpoint->{reverse}" ];
            $rows[0][0] = join('/', '', @parts);
            $paths->row(@$_) for @rows;
        }

        $paths;
    },
);

no Mouse;

sub match {
    my ($self, $req, $path) = @_;
    return if @{ $req->args };

    my @parts = split '/', $path;

    my ($chain, $captures, $parts) = $self->recurse_match($req, '/', \@parts);
    push @{ $req->args }, @$parts if $parts && @$parts;

    return unless $chain;

    my $action = Ark::ActionChain->from_chain($chain);

    $req->action($action);
    $req->match('/' . $action->reverse);
    $req->captures($captures);

    1;
}

sub recurse_match {
    my ($self, $req, $parent, $path_parts) = @_;
    my $children = $self->children_of->{ $parent } or return;

    my $best_action;
    my @captures;

 TRY: for my $try_part (sort { length($b) <=> length($a) } keys %$children) {
        my @parts = @$path_parts;
        if (length $try_part) {
            next TRY
                unless $try_part eq
                    join '/', splice(@parts, 0, scalar @{[split '/', $try_part]});
        }

        my @try_actions = @{ $children->{$try_part} };
    TRY_ACTION: for my $action (@try_actions) {
            if (my $capture_attr = $action->attributes->{CaptureArgs}) {
                next TRY_ACTION unless @parts >= $capture_attr->[0];

                my @captures;
                my @parts = @parts;

                push @captures, splice @parts, 0, $capture_attr->[0];

                my ($actions, $captures, $action_parts) = $self->recurse_match(
                    $req, '/' . $action->reverse, \@parts
                );

                if ($actions
                    && (  !$best_action
                        || $#$action_parts < $#{ $best_action->{parts} }
                        || (   $#$action_parts == $#{ $best_action->{parts} }
                                   && $#captures < $#{ $best_action->{captures} } ))) {
                    $best_action = {
                        actions  => [ $action,   @$actions ],
                        captures => [ @captures, @$captures ],
                        parts    => $action_parts,
                    };
                }
            }
            else {
                {
                    local $req->{arguments} = [ @{$req->args}, @parts ];
                    next TRY_ACTION unless $action->match($req);
                }

                my $args_attr = $action->attributes->{Args}[0];
                if (  !$best_action
                    || @parts < @{ $best_action->{parts} }
                    || ( !@parts && $args_attr eq 0 ) ) {
                    $best_action = {
                        actions  => [$action],
                        captures => [],
                        parts    => \@parts,
                    };
                }
            }
        }
    }
    return @$best_action{qw/actions captures parts/} if $best_action;
    return ();
}

sub register {
    my ($self, $action) = @_;

    my @chained = @{ $action->attributes->{Chained} || [] }
        or return;

    die "Multiple Chained attributes not supported registering $action->{reverse}"
        if @chained > 1;

    my $children = $self->children_of->{ $chained[0] } ||= {};

    my @path_part = @{ $action->attributes->{PathPart} || [] };
    my $part      = defined $path_part[0] ? $path_part[0] : $action->name;

    die "Multiple PathPart attributes not supported registering $action->{reverse}"
        if @path_part > 1;

    die "Absolute parameters to PathPart not allowed registering $action->{reverse}"
        if $part =~ m!^/!;

    $action->attributes->{PathPart} = [ $part ];
    unshift @{ $children->{$part} ||= [] }, $action;

    $self->actions->{ '/' . $action->reverse } = $action;

    unshift @{ $self->endpoints }, $action
        unless $action->attributes->{CaptureArgs};

    1;
}

sub used {
    my $self = shift;
    scalar @{ $self->endpoints }
}

1;

