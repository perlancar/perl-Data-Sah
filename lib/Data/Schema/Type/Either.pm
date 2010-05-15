package Data::Schema::Type::Either;
# ABSTRACT: Specification for 'either' type

=head1 DESCRIPTION

Aliases: B<or>, B<any>

'Either' is not really an actual data type, but a way to validate whether a
value validates to any one of the specified schemas.

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
use Data::Schema::Util 'attr';
with
    'Data::Schema::Type::Base';

our $typenames = ["either", "or", "any"];

=head1 TYPE ATTRIBUTES

Either assumes the role of L<Data::Schema::Type::Base>. Please consult
the documentation of those role(s) to see what type attributes are
available.

In addition, either defines these attributes:

=head2 of => [SCHEMA1, SCHEMA2, ...]

Specify the schema(s), where the value will need to be valid to one of
them.

=cut

attr 'of', arg => '((schema*)[])*';

no Any::Moose;
1;
