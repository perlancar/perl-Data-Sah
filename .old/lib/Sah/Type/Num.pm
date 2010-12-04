package Data::Schema::Spec::v10::Type::Num;
# ABSTRACT: Specification for numeric types

=head1 DESCRIPTION

This is specification for numeric types.

=cut

use Any::Moose '::Role';
use Data::Schema::Util 'attr';
with
    'Data::Schema::Spec::v10::Type::Base',
    'Data::Schema::Spec::v10::Type::Comparable',
    'Data::Schema::Spec::v10::Type::Sortable';

=head1 TYPE ATTRIBUTES

Num assume the roles L<Data::Schema::Spec::v10::Type::Base>,
L<Data::Schema::Spec::v10::Type::Comparable>, and
L<Data::Schema::Spec::v10::Type::Sortable>. Consult the documentation of those
role(s) to see what type attributes are available.

Currently, num does not define additional attributes.

=cut

no Any::Moose;
1;
