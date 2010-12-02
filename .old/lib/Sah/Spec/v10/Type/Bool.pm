package Data::Schema::Spec::v10::Type::Bool;
# ABSTRACT: Specification for 'bool' type

=head1 DESCRIPTION

Aliases: B<boolean>

This is specification for 'bool' type.

=cut

use Any::Moose '::Role';
with
    'Data::Schema::Spec::v10::Type::Base',
    'Data::Schema::Spec::v10::Type::Comparable',
    'Data::Schema::Spec::v10::Type::Sortable';

our $typenames = ["bool", "boolean"];

=head1 TYPE ATTRIBUTES

Bool assumes the roles L<Data::Schema::Spec::v10::Type::Base>,
L<Data::Schema::Spec::v10::Type::Comparable>, and
L<Data::Schema::Spec::v10::Type::Sortable>. Consult the documentation of those
base type and role(s) to see what type attributes are available.

Currently, bool does not define additional attributes.

=cut

no Any::Moose;
1;
