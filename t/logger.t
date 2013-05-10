use strict;
use warnings;
use Test::More;
use Test::Output;


{
    package T;
    use Ark;
}

{
    my $app = T->new( log_level => 'debug' );
    isa_ok $app, 'Ark::Core';

    # old interface
    stderr_is sub { $app->log( debug => 'debug!' ) },
        "[debug] debug!\n", 'old debug ok';

    # new interface
    stderr_is sub { $app->log->debug('debug!') },
        "[debug] debug!\n", 'new debug ok';

    # with args
    stderr_is sub { $app->log( debug => 'debug! %d%d%d', 1, 2, 3 ) },
        "[debug] debug! 123\n", 'old debug with args ok';

    stderr_is sub { $app->log->debug('debug! %d%d%d', 1, 2, 3 ) },
        "[debug] debug! 123\n", 'new debug with args ok';
}

{
    my $app = T->new( log_level => 'info' );
    isa_ok $app->logger, 'Ark::Logger';
    is $app->logger->log_level, 'info', 'log_level ok';
}


done_testing;
