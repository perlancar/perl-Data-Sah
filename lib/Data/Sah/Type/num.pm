package Data::Sah::Type::num;

use Moo::Role;
with 'Data::Sah::Type::BaseType';
with 'Data::Sah::Type::Comparable';
with 'Data::Sah::Type::Sortable';

1;
# ABSTRACT: Specification for num types

=head1 CLAUSES

Unless specified otherwise, all clauses have a priority of 50 (normal).

'num' assumes the roles L<Data::Sah::Type::BaseType>,
L<Data::Sah::Type::Comparable>, and L<Data::Sah::Type::Sortable>. Consult the
documentation of those role(s) to see what clauses are available.

Currently, num does not define additional clauses.

=cut
