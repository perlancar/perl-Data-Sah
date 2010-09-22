package Data::Schema::Spec::v10::Type::Float;
# ABSTRACT: Specification for 'float' type

use Any::Moose '::Role';
with
    'Data::Schema::Spec::v10::Type::Num';

our $typenames = ["float"];

=head1 TYPE ATTRIBUTES

See L<Data::Schema::Spec::v10::Type::Num>.

=cut

no Any::Moose;
1;
