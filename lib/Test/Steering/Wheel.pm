package Test::Steering::Wheel;

use warnings;
use strict;
use TAP::Harness;
use Scalar::Util qw(refaddr);

=head1 NAME

Test::Steering::Wheel - Execute tests and renumber the resulting TAP.

=head1 VERSION

This document describes Test::Steering::Wheel version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    use Test::Steering::Wheel;
    
    my $wheel = Test::Steering::Wheel->new;
    $wheel->include_tests( 'xt/vms/*.t' ) if $^O eq 'VMS';
    $wheel->include_tests( 'xt/windows/*.t' ) if $^O =~ 'MSWin32';

=head1 DESCRIPTION

Behind the scenes in L<Test::Steering> is a singleton instance of
C<Test::Steering::Wheel>.

See L<Test::Steering> for more information.

=head1 INTERFACE 

=head2 C<< new >>

Create a new C<Test::Steering::Wheel>.

=cut

sub new {
    my $class = shift;
    my %args  = @_;

    my $self = bless { test_number_adjust => 0, }, $class;
    return $self;
}

=for private

Output demultiplexer. Handles output associated with multiple parsers.
If parsers output sequentially no buffering is done. If, however, output
from multiple parsers is interleaved output from the first encountered
will be echoed directly and output from all the others will be buffered.

After a parser finishes (calls $done) the next parser to generate output
will have its buffer flushed and will start output directly.

The upshot of all this is that we output from multiple parsers doing the
minimum amount of buffering necessary to keep per-parser output ordered.

=cut

sub _output_demux {
    my ( $self, $printer, $complete ) = @_;
    my $current_id = undef;
    my %queue_for  = ();
    my @completed  = ();

    my $finish = sub {
        while ( my $job = shift @completed ) {
            my ( $parser, $buffered ) = @$job;
            $printer->( @$_ ) for @$buffered;
            $complete->( $parser );
        }
    };

    return (
        # demux
        sub {
            my ( $parser, $type, $line ) = @_;
            my $id = refaddr $parser;

            unless ( defined $current_id ) {
                # Our chance to take over...
                if ( my $buffered = delete $queue_for{$id} ) {
                    $printer->( @$_ ) for @$buffered;
                }
                $current_id = $id;
            }

            if ( $current_id == $id ) {
                $printer->( $type, $line );
            }
            else {
                push @{ $queue_for{$id} }, [ $type, $line ];
            }

        },
        # done
        sub {
            my $parser = shift;
            my $id     = refaddr $parser;
            if ( defined $current_id && $current_id == $id ) {
                # Finished the current one so allow another to
                # take over
                $complete->( $parser );
                undef $current_id;
                # Flush any others that have completed in the mean time
                $finish->();
            }
            else {
                # Add to completed list
                push @completed, [ $parser, delete $queue_for{$id} ];
            }
        },
        # finish
        $finish,
    );
}

# Like ok
sub _output_result {
    my ( $self, $ok, $description ) = @_;
    printf( "%sok %d %s\n",
        $ok ? '' : 'not ',
        ++$self->{test_number_adjust}, $description );
}

=for private

Output additional test failures if our subtest had problems.

=cut

sub _parser_postmortem {
    my ( $self, $parser ) = @_;

    $self->_output_result( 0, "Parse error: $_" )
      for $parser->parse_errors;

    my ( $wait, $exit ) = ( $parser->wait, $parser->exit );
    $self->_output_result( 0,
        "Non-zero status: exit=$exit, wait=$wait" )
      if $exit || $wait;
}

=head2 C<< include_tests >>

Run one or more tests. Wildcards will be expanded.

    include_tests( 'xt/vms/*.t' ) if $^O eq 'VMS';
    include_tests( 'xt/windows/*.t' ) if $^O =~ 'MSWin32';

=cut

sub include_tests {
    my ( $self, @tests ) = @_;

    my %options = ( verbosity => -9 );
    my @real_tests = ();

    # Split options hashes from tests
    for my $t ( @tests ) {
        if ( 'HASH' eq ref $t ) {
            %options = ( %options, %$t );
        }
        else {
            push @real_tests, grep { !$self->{seen}->{$_} } glob $t;
        }
    }
    
    $self->{seen}->{$_}++ for @real_tests;

    my $harness = TAP::Harness->new( \%options );

    my $printer = sub {
        my ( $type, $line ) = @_;
        print "TAP version 13\n" unless $self->{started}++;
        if ( $type eq 'test' ) {
            $line =~ s/(\d+)/$1 + $self->{test_number_adjust}/e;
        }
        print $line;
    };

    my $complete = sub {
        my $parser    = shift;
        my $tests_run = $parser->tests_run;
        $self->{test_number_adjust} += $parser->tests_run;
    };

    my ( $demux, $done, $finish )
      = $self->_output_demux( $printer, $complete );

    $harness->callback(
        made_parser => sub {
            my $parser = shift;
            $parser->callback( plan    => sub { } );
            $parser->callback( version => sub { } );
            $parser->callback(
                test => sub {
                    my $test = shift;
                    my $raw  = $test->as_string;
                    $demux->( $parser, 'test', "$raw\n" );
                }
            );
            $parser->callback(
                ELSE => sub {
                    my $result = shift;
                    $demux->( $parser, 'raw', $result->raw, "\n" );
                }
            );
            $parser->callback(
                EOF => sub {
                    $self->_parser_postmortem( $parser );
                    $done->( $parser );
                }
            );
        }
    );

    my $aggregator = $harness->runtests( @real_tests );
    $finish->();
}

=head2 C<end_plan>

=cut

sub end_plan {
    my $self = shift;
    if ( my $plan = $self->{test_number_adjust} ) {
        print "1..$plan\n";
        $self->{test_number_adjust} = 0;
    }
}

1;
__END__

=head1 CONFIGURATION AND ENVIRONMENT
  
Test::Steering::Wheel requires no configuration files or environment variables.

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
