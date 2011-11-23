package Data::Sah::Type::int;

use Moo::Role;
use Data::Sah::Util 'clause';
with 'Data::Sah::Type::num';

clause 'mod', arg => [['int*' => {isnt=>0}], 'int*'];

1;
# ABSTRACT: Specification for int type

=head1 CLAUSES

'int' assumes the following role: L<Data::Sah::Type::Num>. Consult the
documentation of the base type to see what type clauses are available.

In addition, 'int' defines these clauses:

=head2 mod => [X, Y]

Require that (data mod X) equals Y. For example, mod => [2, 1] effectively
specifies odd numbers.

=cut

=head2 div_by => INT

Require that data is divisible by a number.

Example:

Given schema [int=>{div_by=>2}], 2, 4, and 6 are valid. Given schema

=cut

clause 'div_by', arg => ['int*' => {isnt=>0}];

=head2 indiv_by => INT

Opposite of B<div_by>.

=cut

clause 'indiv_by', arg => ['int*' => {isnt=>0}];

1;
