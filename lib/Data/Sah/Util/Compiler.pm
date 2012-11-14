package Data::Sah::Util::Compiler;

use 5.010;
use strict;
use warnings;
use Log::Any '$log';

# VERSION

#use Sub::Install qw(install_sub);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       add_clause
                       add_func
               );

sub add_clause {
    my ($type, $clause, %opts) = @_;
    # not yet implemented

    # * call Data::Sah::Util::Role::has_clause
    # * install handlers to Data::Sah::Compiler::$Compiler::TH::$type
    # * add translation path so that
    #   Data::Sah::Lang::$Lang::TypeX::$type::$clause is also searched
}

sub add_func {
    my ($funcset, $func, %opts) = @_;
    # not yet implemented
}

1;
# ABSTRACT: Sah utility routines for compilers

=head1 DESCRIPTION

This module provides some utility routines to be used in compilers
(C<Data::Sah::Compiler::*>).


=head1 FUNCTIONS

=head2 add_clause($type, $clause, %opts)

Add a clause. Used when wanting to add a clause to an existing type.

Options:

=over 4

=item * definition => HASH

Will be passed to L<Data::Sah::Util::Role>'s C<has_clause>.

=item * handlers => HASH

A mapping of compiler name and coderefs. Coderef will be installed as
C<clause_$clause> in the C<Data::Sah::Compiler::$Compiler::TH::

At least C<perl>, C<

=item * prio => $priority

Optional. Default is 50. The higher the priority, the earlier the clause will be
processed.

=item * aliases => \@aliases OR $alias

Define aliases. Optional.

=item * code => $code

Optional. Define implementation for the clause. The code will be installed as
'clause_$name'.

=back

=head2 add_func($funcset, $func, %opts)

=cut
