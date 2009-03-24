package Ark::Plugin;
use Mouse::Role;

sub import {
    my $class   = shift;
    my $target_context = shift || '';

    require strict; strict->import;
    require warnings; warnings->import;
    require utf8; utf8->import;

    my $caller = caller;
    my $meta   = Mouse::Meta::Role->initialize($caller);

    {
        no strict 'refs';
        for my $keyword (@Mouse::Role::EXPORT) {
            *{ $caller . '::' . $keyword } = *{ 'Mouse::Role::' . $keyword };
        }
        *{ $caller . '::meta' }           = sub { $meta };
        *{ $caller . '::plugin_context' } = sub { $target_context };
        *{ $caller . '::method' } = sub {
            my ($self, $method) = @_;
            my $caller = caller;
            my $sub = $caller->can($method) or die qq/No such method "$method" on $caller/;

            return sub { $sub->($self, @_) };
        };
    }
}

1;
