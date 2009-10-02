use MyApp;

my $app = MyApp->new;
$app->setup;
$app->psgi_handler;
