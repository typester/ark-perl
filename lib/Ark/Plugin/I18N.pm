package Ark::Plugin::I18N;
use Ark::Plugin;

use I18N::LangTags ();
use I18N::LangTags::Detect;

require Locale::Maketext::Simple;

sub BUILD {
    my $self  = shift;
    my $stash = $self->class_stash;

    return if $stash->{setup_finished};

    my $class = ref($self->app);
    my $path  = $self->path_to('lib', $class, 'I18N');

    eval <<"";
        package $class;
        Locale::Maketext::Simple->import(
            Class  => '$class',
            Path   => '$path',
            Export => '_loc',
            Decode => 1
        );

    if ($@) {
        $self->log( error => qq/Couldn't initialize i18n "$class\::I18N", "$@"/ );
    }
    else {
        $self->log( debug => qq/Initialized i18n "$class\::I18N"/);
    }

    $stash->{setup_finished}++;
}

sub languages {
    my ($self, $languages) = @_;

    if ($languages) {
        $self->{languages} = ref($languages) eq 'ARRAY' ? $languages : [$languages];
    }
    else {
        $self->{languages} ||= [
            I18N::LangTags::implicate_supers(
                I18N::LangTags::Detect->http_accept_langs(
                    $self->request->header('Accept-Language'),
                ),
            ),
            'i-default',
        ];
    }

    if (my $mt = $self->app->can('_loc_lang')) {
        $mt->(@{ $self->{languages} });
    }
    $self->{languages};
}

sub language {
    my $self  = shift;
    my $class = ref($self->app);

    "${class}::I18N"->get_handle(@{ $self->languages })->language_tag;
}

{
    no warnings 'once';
    *loc = \&localize;
}

sub localize {
    my $self = shift;
    $self->languages;

    my $loc = $self->app->can('_loc') or return;
    if (ref $_[1] eq 'ARRAY') {
        return $loc->( $_[0], @{ $_[1] } );
    }
    else {
        return $loc->(@_);
    }
}

1;
