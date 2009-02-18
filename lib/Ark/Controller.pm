package Ark::Controller;
use Mouse;
use HTTP::Engine::Response;

extends 'Ark::Component', 'Class::Data::Inheritable';

our @EXPORT = qw/response/;

__PACKAGE__->mk_classdata($_) for qw/_attr_cache _method_cache/;
__PACKAGE__->_attr_cache( [] );
__PACKAGE__->_method_cache( {} );

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

    push @{ $class->_attr_cache }, [ $code, \@attrs ];
    return;
}

sub response {
    HTTP::Engine::Response->new(@_);
}

1;
