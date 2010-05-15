package Data::Schema::Type::Float;
# ABSTRACT: Specification for 'float' type

use Any::Moose '::Role';
with
    'Data::Schema::Type::Num';

our $typenames = ["float"];

=head1 TYPE ATTRIBUTES

See L<Data::Schema::Type::Num>.

=cut

no Any::Moose;
1;
