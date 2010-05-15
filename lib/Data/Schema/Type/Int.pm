package Data::Schema::Type::Int;
# ABSTRACT: Specification for 'int' type

use Any::Moose '::Role';
use Data::Schema::Util 'attr';
with
    'Data::Schema::Type::Num';

our $typenames = ["int", "integer"];

=head1 TYPE ATTRIBUTES

'Int' assumes the following role: L<Data::Schema::Type::Num>. Consult
the documentation of the base type to see what type attributes are
available.

In addition, 'int' defines these attributes:

=head2 mod => [X, Y]

Require that (data mod X) equals Y. For example, mod => [2, 1]
effectively specifies odd numbers.

=cut

attr 'mod', arg => [['int*' => {not=>0}], 'int*'];

=head2 divisible_by => INT or ARRAY

Require that data is divisible by all specified numbers.

Example:

 ds_validate( 4, [int=>{divisible_by=>2}]     ); # valid
 ds_validate( 4, [int=>{divisible_by=>[2,3]}] ); # invalid
 ds_validate( 6, [int=>{divisible_by=>[2,3]}] ); # valid

=cut

attr 'divisible_by', arg => 'int*|((int*)[])*';

=head2 not_divisible_by => INT or ARRAY

Aliases: B<indivisible_by>

Opposite of B<divisible_by>.

=cut

attr 'not_divisible_by', alias => 'indivisible_by', arg => 'int*|((int*)[])*';

no Any::Moose;
1;
