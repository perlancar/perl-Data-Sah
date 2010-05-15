package Data::Schema::Type::Num;
# ABSTRACT: Specification for numeric types

=head1 DESCRIPTION

This is specification for numeric types.

=cut

use Any::Moose '::Role';
use Data::Schema::Util 'attr';
with
    'Data::Schema::Type::Base',
    'Data::Schema::Type::Comparable',
    'Data::Schema::Type::Sortable';

=head1 TYPE ATTRIBUTES

Num assume the roles L<Data::Schema::Type::Base>,
L<Data::Schema::Type::Comparable>, and
L<Data::Schema::Type::Sortable>. Consult the documentation of those
role(s) to see what type attributes are available.

Currently, num does not define additional attributes.

=cut

no Any::Moose;
1;
