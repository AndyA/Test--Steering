package Test::Steering;

use warnings;
use strict;
use Test::Steering::Wheel;
use Exporter;

=head1 NAME

Test::Steering - Execute test scripts conditionally

=head1 VERSION

This document describes Test::Steering version 0.02

=cut

our $VERSION = '0.02';
our @ISA     = qw(Exporter);
our @EXPORT;
our $WHEEL_CLASS = 'Test::Steering::Wheel';

BEGIN {
    @EXPORT = qw(include_tests end_plan);
    my $WHEEL;
    for my $method ( @EXPORT ) {
        no strict 'refs';
        *{ __PACKAGE__ . '::' . $method } = sub {
            return ( $WHEEL ||= _make_wheel() )->$method( @_ );
        };
    }
}

=head1 SYNOPSIS

    use Test::Steering;

    include_tests( 'xt/vms/*.t' ) if $^O eq 'VMS';
    include_tests( 'xt/windows/*.t' ) if $^O =~ 'MSWin32';

=head1 DESCRIPTION

Often it is useful to have more control over which tests are executed
- and how. You can exercise some degree of control by SKIPping
unwanted tests but that can be inefficient and cumbersome for large
test suites.

C<Test::Steering> runs test scripts and filters their output into a
single, syntactically correct TAP stream. In this way a single test
script can be responsible for running multiple other tests.

The parameters for the L<TAP::Harness> used run the subtests can also
be controlled making it possible to, for example, run certain tests
in parallel.

At some point in the future it is likely that TAP syntax will be
extended to support hierarchical results. See

    http://testanything.org/wiki/index.php/Test_Groups
    http://testanything.org/wiki/index.php/Test_Blocks

for proposed schemes.

When hierarchical TAP is implemented this module will be upgraded to
support it.

=head1 INTERFACE 

=head2 C<< include_tests >>

Run one or more tests. Wildcards will be expanded.

    include_tests( 'xt/vms/*.t' ) if $^O eq 'VMS';
    include_tests( 'xt/windows/*.t' ) if $^O =~ 'MSWin32';

Behind the scenes a new L<TAP::Harness> will be created and used to run
the individual test scripts. The output test results are concatenated,
tests renumbered and then sent to STDOUT. The net effect of which is
that multiple tests are able to masquerade as a single test.

If there are any problems running the tests (TAP syntax errors, non-zero
exit status) those will be turned into additional test failures.

In addition to test names you may pass hash references which will be passed
to C<< TAP::Harness->new >>.

    # Run tests in parallel
    include_tests( { jobs => 9 }, 'xt/parallel/*/t' );

Multiple options hashes may be provided; they will be concatenated.

    # Run tests in parallel, enable warnings
    include_tests( { jobs => 9 },
        'xt/parallel/*/t', { switches => ['-w'] } );

=head2 C<< end_plan >>

Output the trailing plan. Normally there is no need to call C<end_plan>
directly: it is called on exit.

=cut

sub _make_wheel {
    return $WHEEL_CLASS->new;
}

END {
    end_plan();
}

1;
__END__

=head1 CONFIGURATION AND ENVIRONMENT
  
Test::Steering requires no configuration files or environment variables.

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-test-steering@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Andy Armstrong  C<< <andy@hexten.net> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Andy Armstrong C<< <andy@hexten.net> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
