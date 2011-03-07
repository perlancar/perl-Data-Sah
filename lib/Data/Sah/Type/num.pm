package Data::Sah::Type::num;
# ABSTRACT: Specification for num types

=head1 DESCRIPTION

This is specification for num types.

=cut

use Moo::Role;
use Data::Sah::Util 'clause';
with 'Data::Sah::Type::BaseType';
with 'Data::Sah::Type::Comparable';
with 'Data::Sah::Type::Sortable';

=head1 CLAUSES

'num' assumes the roles L<Data::Sah::Type::Base>, L<Data::Sah::Type::Comparable>, and
L<Data::Sah::Type::Sortable>. Consult the documentation of those role(s) to see what
clauses are available.

Currently, num does not define additional clauses.

=cut

1;
