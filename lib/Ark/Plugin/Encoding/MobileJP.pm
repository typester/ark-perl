package Ark::Plugin::Encoding::MobileJP;
use Ark::Plugin;

use Encode;
use Encode::JP::Mobile ':props';
use Encode::JP::Mobile::Character;
use HTTP::MobileAgent::Plugin::Charset;

has encoding => (
    is      => 'ro',
    isa     => 'Object',
    lazy    => 1,
    default => sub {
        my ($c) = @_;

        unless ($c->can('mobile_agent')) {
            die 'Plugin::Encoding::MobileJP is required Plugin::MobileAgent';
        }

        my $encoding = $c->mobile_agent->encoding;
        ref($encoding) && $encoding->isa('Encode::Encoding')
            ? $encoding
            : Encode::find_encoding($encoding);
    },
);

sub prepare_encoding {
    my ($c) = @_;
    my $req = $c->request;

    my $encode = sub {
        my ($p, $skip) = @_;

        if (blessed $p and $p->isa('Hash::MultiValue')) {
            return if $skip;
            $p->each(sub {
                $_[1] = decode($c->encoding, $_[1]);
            });
        }
        else {
            # backward compat
            for my $value (values %$p) {
                next if ref $value and ref $value ne 'ARRAY';
                $_ = decode($c->encoding, $_) for ref $value ? @$value : ($value);
            }
        }
    };

    $encode->($req->query_parameters);
    $encode->($req->body_parameters);

    $req->env->{'plack.request.merged'} = undef; #clear cache
    $encode->($req->parameters, 1);
}

my %htmlspecialchars = ( '&' => '&amp;', '<' => '&lt;', '>' => '&gt;', '"' => '&quot;' );
my $htmlspecialchars = join '', keys %htmlspecialchars;

sub finalize_encoding {
    my ($c) = @_;

    if (!$c->res->binary and $c->res->has_body) {
        my $body = $c->res->body;

        $body = encode($c->encoding, $body, sub {
            my $char = shift;
            my $out  = Encode::JP::Mobile::FB_CHARACTER()->($char);
            
            if ($c->res->content_type =~ /html$|xml$/) {
                $out =~ s/([$htmlspecialchars])/$htmlspecialchars{$1}/ego; # for (>３<)
            }
        
            $out;
        });
        
        $c->res->body($body);
    }
}

1;
