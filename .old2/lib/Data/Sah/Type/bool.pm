package Data::Sah::Type::bool;
# ABSTRACT: Specification for 'bool' type

=head1 DESCRIPTION

This is specification for 'bool' type.

=cut

use Moo::Role;
with 'Data::Sah::Type::BaseType';
with 'Data::Sah::Type::Comparable';
with 'Data::Sah::Type::Sortable';

# VERSION

=head1 CLAUSES

Bool assumes the roles L<Data::Sah::Type::Base>, L<Data::Sah::Type::Comparable>, and
L<Data::Sah::Type::Sortable>. Consult the documentation of those base type and role(s)
to see what type clauses are available.

Currently, bool does not define additional clauses.

=cut

1;
