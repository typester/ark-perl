package Ark::Plugin::CSRFDefender;
use strict;
use warnings;
use Ark::Plugin;

our $SESSION_NAME = 'csrf_token';
our $PARAM_NAME   = 'csrf_token';
our $RANDOM_STRING_SIZE = 16;

sub csrf_token {
    my $c = shift;
    my $req = $c->request;

    if (my $token = $c->session->get($SESSION_NAME)) {
        return $token;
    }
    else {
        my $token = _random_string($RANDOM_STRING_SIZE);

        $c->session->set($SESSION_NAME => $token);
        return $token;
    }
}

sub validate_csrf_token {
    my $c = shift;
    my $req = $c->request;

    if (_is_need_validated($req->method)) {
        my $param_token   = $req->param($PARAM_NAME);
        my $session_token = $c->session->get($SESSION_NAME);

        if (!$param_token || !$session_token || ($param_token ne $session_token)) {
            return 0; # bad
        }
    }
    return 1; # good
}

sub html_filter_for_csrf {
    my ($c, $html) = @_;
    return if !$html;

    my $token = $c->csrf_token;
    $html =~ s!(<form\s*.*?>)!$1\n<input type="hidden" name="$PARAM_NAME" value="$token" />!isg;

    return $html;
}

sub _is_need_validated {
    my ($method) = @_;
    return 0 if !$method;

    return
        $method eq 'POST'   ? 1 :
        $method eq 'PUT'    ? 1 :
        $method eq 'DELETE' ? 1 : 0;
}

sub _random_string {
    my $length = shift;
    my @chars = ('A'..'Z', 'a'..'z', '0'..'9', '$', '!');
    my $ret;
    for (1..$length) {
        $ret .= $chars[int rand @chars];
    }
    return $ret;
}

1;
__END__

=head1 NAME

Ark::Plugin::CSRFDefender - CSRF Defender for Ark

=head1 SYNOPSIS

    use Ark::Plugin::CSRFDefender;
    # lib/MyApp.pm
    use_plugins qw(
        CSRFDefender
    );

    # lib/MyApp/Controller/Root.pm
    sub auto :Private {
        my ($self, $c) = @_;

        # CSRF対策
        if (!$c->validate_csrf_token) {
            $self->res->code(403);
            $self->res->body("CSRF ERROR");
            $self->detach;
        }

        ...;

    }

    # lib/MyApp/View/Xslate.pm
    sub render {
        my ($self, $template) = @_;
        my $c = $self->context;

        my $html = $self->xslate->render($template);
        $html = $c->html_filter_for_csrf($html);

        return $html;
    }

=head1 METHODS

=head2 C<< $c->csrf_token -> Str >>

=head2 C<< $c->validate_csrf_token -> Bool >>

=head2 C<< $c->html_filter_for_csrf($html) -> Str >>

=head1 SEE ALSO

L<Amon2::Plugin::Web::CSRFDefender>, L<Mojolicious::Plugin::CSRFDefender>

=cut
