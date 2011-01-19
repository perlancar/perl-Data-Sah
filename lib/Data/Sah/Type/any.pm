package Data::Sah::Type::any;
# ABSTRACT: Specification for 'any' type

=head1 DESCRIPTION

'Any' is not really an actual data type, but a way to validate whether a value
validates to any one of the specified schemas.

Example schema:

 [any => {of => [
   [int => {divisible_by: 2}],
   [int => {divisible_by: 7}],
 ]}]

Example valid data:

 42  # divisible by 2 as well as 7
 21  # not divisible by 2 but divisible by 7
 4   # not divisible by 7 but divisible by 2

Example invalid data:

 15  # not divisible by 2 nor 7

=cut

use Any::Moose '::Role';
use Data::Sah::Util 'clause';
with
    'Data::Sah::Type::BaseType';

=head1 CLAUSES

Any assumes the role of L<Data::Sah::Type::Base>. Please consult the documentation of
those role(s) to see what type clauses are available.

In addition, either defines these clauses:

=head2 of => [SCHEMA1, SCHEMA2, ...]

Specify the schema(s), where the value will need to be valid to one of them.

=cut

clause 'of', arg => '((schema*)[])*';

no Any::Moose;
1;
