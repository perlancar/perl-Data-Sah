package Data::Schema::Type::All;
# ABSTRACT: Specification for 'all' type

=head1 DESCRIPTION

Aliases: B<and>

'All' is not really an actual data type, but a way to validate whether a
value validates to all of the specified schemas.

Example schema:

 [all => { of => [
     [int => {divisible_by=>2}],
     [int => {divisible_by=>7}],
 ]}]

Example valid data:

 42  # divisible by 2 as well as 7

Example invalid data:

 21  # divisible by 7 but not by 2

 4   # divisible by 2 but not by 7

 15  # not divisible by 2 nor 7

=cut

use Any::Moose '::Role';
use Data::Schema::Util 'attr', 'attr_conflict';
with 'Data::Schema::Type::Base';

our $typenames = ["all", "and"];

=head1 TYPE ATTRIBUTES

'All' assumes the following role: L<Data::Schema::Type::Base>. Consult
the documentation of those role(s) to see what type attributes are
available.

In addition, 'all' defines these attributes:

=head2 of => [schema1, schema2, ...]

Specify the schema(s), where the value will need to be valid to all of
them.

=cut

attr 'of',
    arg => '(schema[])*';

1;
