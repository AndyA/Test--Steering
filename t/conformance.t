use strict;
use warnings;
use Test::More;
use Test::Steering::Wheel;
use IO::Capture::Stdout;
use File::Spec;

my @TEST_PATH = ( 't', 'sample-tests' );

my @schedule = (
    {
        args   => [ tp( 'simple' ) ],
        expect => [
            "TAP version 13\n",
            "ok 1\n", "ok 2\n", "ok 3\n", "ok 4\n", "ok 5\n", "1..5\n",
        ],
    },
    {
        args   => [ tp( 'descriptive' ) ],
        expect => [
            "TAP version 13\n",
            "ok 1 Interlock activated\n",
            "ok 2 Megathrusters are go\n",
            "ok 3 Head formed\n",
            "ok 4 Blazing sword formed\n",
            "ok 5 Robeast destroyed\n",
            "1..5\n"
        ],
    },
    {
        args   => [ tp( 'simple' ), tp( 'simple_fail' ) ],
        expect => [
            "TAP version 13\n",
            "ok 1\n",
            "ok 2\n",
            "ok 3\n",
            "ok 4\n",
            "ok 5\n",
            "ok 6\n",
            "not ok 7\n",
            "ok 8\n",
            "ok 9\n",
            "not ok 10\n",
            "1..10\n",
        ],
    },
    {
        args   => [ tp( 'die' ) ],
        expect => [
            "not ok 1 Parse error: No plan found in TAP output\n",
            "not ok 2 Non-zero status: exit=1, wait=256\n",
            "1..2\n"
        ],
    },
    {
        args   => [ tp( 'simple_yaml' ) ],
        expect => [
            "TAP version 13\n",
            "ok 1\n",
            "ok 2\n",
            "  ---\n  -\n    fnurk: skib\n    ponk: gleeb\n  -\n"
              . "    bar: krup\n    foo: plink\n  ...",
            "ok 3\n",
            "ok 4\n",
            "  ---\n  expected:\n    - 1\n    - 2\n    - 4\n  got:\n"
              . "    - 1\n    - pong\n    - 4\n  ...",
            "ok 5\n",
            "1..5\n"
        ],
    },
    {
        args   => [ tp( 'no_nums' ) ],
        expect => [
            "TAP version 13\n",
            "ok 1\n",
            "ok 2\n",
            "not ok 3\n",
            "ok 4\n",
            "ok 5\n",
            "1..5\n"
        ],
    },
    {
        args => [
            tp( 'simple' ),
            tp( 'simple_fail' ),
            tp( 'die' ),
            tp( 'simple_yaml' ),
            tp( 'no_nums' )
        ],
        expect => [
            "TAP version 13\n",
            "ok 1\n",
            "ok 2\n",
            "ok 3\n",
            "ok 4\n",
            "ok 5\n",
            "ok 6\n",
            "not ok 7\n",
            "ok 8\n",
            "ok 9\n",
            "not ok 10\n",
            "not ok 11 Parse error: No plan found in TAP output\n",
            "not ok 12 Non-zero status: exit=1, wait=256\n",
            "ok 13\n",
            "ok 14\n",
            "  ---\n  -\n    fnurk: skib\n    ponk: gleeb\n  -\n"
              . "    bar: krup\n    foo: plink\n  ...",
            "ok 15\n",
            "ok 16\n",
            "  ---\n  expected:\n    - 1\n    - 2\n    - 4\n  got:\n"
              . "    - 1\n    - pong\n    - 4\n  ...",
            "ok 17\n",
            "ok 18\n",
            "ok 19\n",
            "not ok 20\n",
            "ok 21\n",
            "ok 22\n",
            "1..22\n"
        ],
    }
);

plan tests => @schedule * 2;

for my $test ( @schedule ) {
    my $wheel = Test::Steering::Wheel->new;
    isa_ok $wheel, 'Test::Steering::Wheel';

    my @args = @{ $test->{args} };
    my $desc = join( ', ', grep { !ref $_ } @args );

    my $capture = IO::Capture::Stdout->new;
    $capture->start;
    $wheel->include_tests( @args );
    $wheel->end_plan;
    $capture->stop;
    my @got = $capture->read;
    unless ( is_deeply \@got, $test->{expect}, "$desc: Output matches" )
    {
        use Data::Dumper;
        diag(
            Data::Dumper->new(
                [
                    {
                        got    => \@got,
                        expect => $test->{expect}
                    }
                ]
              )->Terse( 1 )->Purity( 1 )->Useqq( 1 )->Dump
        );
    }
}

sub tp { File::Spec->catfile( @TEST_PATH, $_[0] ) }
