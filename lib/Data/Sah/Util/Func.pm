package Data::Sah::Util::Func;

use 5.010;
use strict;
use warnings;
use Log::Any '$log';

# VERSION

#use Sub::Install qw(install_sub);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       add_func
               );

sub add_func {
    my ($funcset, $func, %opts) = @_;
    # not yet implemented
}

1;
# ABSTRACT: Sah utility routines for adding function

=head1 DESCRIPTION

This module provides some utility routines to be used by modules that add Sah
functions.


=head1 FUNCTIONS

=head2 add_func($funcset, $func, %opts)

=cut
