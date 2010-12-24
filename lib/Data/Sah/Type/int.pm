package Data::Sah::Type::int;
# ABSTRACT: Specification for int type

use Any::Moose '::Role';
use Sah::Util 'clause';
with
    'Sah::Type::num';

=head1 CLAUSES

'int' assumes the following role: L<Data::Sah::Type::Num>. Consult the documentation of
the base type to see what type clauses are available.

In addition, 'int' defines these clauses:

=head2 mod => [X, Y]

Require that (data mod X) equals Y. For example, mod => [2, 1] effectively
specifies odd numbers.

=cut

clause 'mod', arg => [['int*' => {isnt=>0}], 'int*'];

=head2 divisible_by => INT

Require that data is divisible by a number.

Example:

Given schema [int=>{divisible_by=>2}], 2, 4, and 6 are valid. Given schema

=cut

clause 'divisible_by', arg => ['int*' => {isnt=>0}];

=head2 indivisible_by => INT

Opposite of B<divisible_by>.

=cut

clause 'indivisible_by', arg => ['int*' => {isnt=>0}];

no Any::Moose;
1;
