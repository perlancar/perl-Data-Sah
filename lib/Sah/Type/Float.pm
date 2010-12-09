package Sah::Type::Float;
# ABSTRACT: Specification for 'float' type

use Any::Moose '::Role';
with
    'Sah::Type::Num';

our $type_names = ["float"];

=head1 CLAUSES

See L<Sah::Type::Num>.

=cut

no Any::Moose;
1;
