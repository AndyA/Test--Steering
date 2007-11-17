package Test::Steering;

use warnings;
use strict;
use Test::Steering::Wheel;
use Exporter;

=head1 NAME

Test::Steering - Execute test scripts conditionally

=head1 VERSION

This document describes Test::Steering version 0.01

=cut

our $VERSION = '0.01';
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

=head1 INTERFACE 

=head2 C<< include_tests >>

=head2 C<< end_plan >>

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
