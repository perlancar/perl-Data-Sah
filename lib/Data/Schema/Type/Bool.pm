package Data::Schema::Type::Bool;
# ABSTRACT: Specification for 'bool' type

=head1 DESCRIPTION

Aliases: B<boolean>

This is specification for 'bool' type.

=cut

use Any::Moose '::Role';
with
    'Data::Schema::Type::Base',
    'Data::Schema::Type::Comparable',
    'Data::Schema::Type::Sortable';

our $typenames = ["bool", "boolean"];

=head1 TYPE ATTRIBUTES

Bool assumes the roles L<Data::Schema::Type::Base>,
L<Data::Schema::Type::Comparable>, and
L<Data::Schema::Type::Sortable>. Consult the documentation of those
base type and role(s) to see what type attributes are available.

Currently, bool does not define additional attributes.

=cut

no Any::Moose;
1;
