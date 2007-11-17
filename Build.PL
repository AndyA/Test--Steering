use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Test::Steering',
    license           => 'perl',
    dist_author       => 'Andy Armstrong <andy@hexten.net>',
    dist_version_from => 'lib/Test/Steering.pm',
    requires          => {
        'Test::More' => 0,
    },
    add_to_cleanup => ['Test-Steering-*'],
);

$builder->create_build_script();
