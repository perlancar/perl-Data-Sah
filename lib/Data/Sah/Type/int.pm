package Data::Sah::Type::int;

use Moo::Role;
use Data::Sah::Util 'has_clause';
with 'Data::Sah::Type::num';

has_clause 'mod', arg => [['int*' => {isnt=>0}], 'int*'];
has_clause 'div_by', arg => ['int*' => {isnt=>0}];
has_clause 'indiv_by', arg => ['int*' => {isnt=>0}];

1;
# ABSTRACT: Specification for type 'int'

=head1 CLAUSES

Unless specified otherwise, all clauses have a priority of 50 (normal).

'int' assumes the following role: L<Data::Sah::Type::num>. Consult the
documentation of the base type to see what type clauses are available.

In addition, 'int' defines these clauses:

=head2 mod => [X, Y]

Require that (data mod X) equals Y. For example, mod => [2, 1] effectively
specifies odd numbers.

=head2 div_by => INT

Require that data is divisible by a number. This is effectively just a shortcut
for 'mod => [N, 0]'.

Example:

Given schema [int=>{div_by=>2}], undef, 0, 2, 4, and 6 are valid but 1, 3, 5 are
not.

=cut

1;
