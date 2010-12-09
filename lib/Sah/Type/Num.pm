package Sah::Type::Num;
# ABSTRACT: Specification for numeric types

=head1 DESCRIPTION

Names: B<num>, B<numeric>, B<number>.

This is specification for numeric types.

=cut

use Any::Moose '::Role';
use Sah::Util 'clause';
with
    'Sah::Type::Base',
    'Sah::Type::Comparable',
    'Sah::Type::Sortable';

our $type_names = ['num', 'number', 'numeric'];

=head1 CLAUSES

Num assume the roles L<Sah::Type::Base>, L<Sah::Type::Comparable>, and
L<Sah::Type::Sortable>. Consult the documentation of those role(s) to see what
clauses are available.

Currently, num does not define additional clauses.

=cut

no Any::Moose;
1;
