package Data::Sah::Type::array;
# ABSTRACT: Specification for 'array' type

=head1 DESCRIPTION

This is the specification for arrays (or arrayrefs in Perl, to be exact).

Example schema:

 [array => {minlen => 1, maxlen => 3, elem_regex => {'.*' => 'int'} }]

The above schema says that the array must have one to three elements, and all
elements must be integers.

Example valid data:

 [1, 2]

Example invalid data:

 []          # too short
 [1,2,3,4]   # too long
 ['x']       # element not integer

=cut

use Any::Moose '::Role';
use Data::Sah::Util 'clause', 'clause_alias';
with
    'Data::Sah::Type::Base',
    'Data::Sah::Type::Comparable',
    'Data::Sah::Type::HasElems';

=head1 CLAUSES

Array assumes the following roles: L<Data::Sah::Type::Base>, L<Data::Sah::Type::Comparable>,
L<Data::Sah::Type::HasElement>. Consult the documentation of those role(s) to see what
type clauses are available.

In addition, there are other clauses for 'array':

=head2 unique => 0|1|undef

If unique is 1, require that the array values be unique (like in a set). If
unique is 0, require that there are duplicates in the array.

=cut

clause 'unique', arg => 'bool';

=head2 elems => [SCHEMA_FOR_FIRST_ELEMENT, SCHEMA_FOR_SECOND_ELEM, ...]

Require that each element of the array validates to the specified schemas.

Note: filters applied by SCHEMA's to elements will be preserved.

Example:

 [array => {elems => [ 'int', 'str', [int => {min=>0}] ]}]

The above example states that the array must have an int as the first element,
string as the second, and positive integer as the third.

=cut

clause 'elems', arg => 'schema[]';

=head2 of => SCHEMA

Requires that every element of the array validates to the specified schema. This
is actually just an alias to HasElement's all_elems.

=cut

clause_alias all_elems => 'of';

=head2 some_of => [[SCHEMA, MIN, MAX], [SCHEMA2, MIN, MAX], ...]

Requires that some elements validates to some schema. MIN and MAX are numbers, -1
means unlimited.

Example:

 [array => {some_of => [
   [[int => {lt=>0}] => 1, -1],
   [[int => {gt=>0}] => 1, -1],
   [float => 3, 3],
  ]}]

The above requires that the array contains at least one positive integer, one
negative integer, exactly three floating numbers, e.g.: [1, -1, 1.5, "str"].

=cut

clause 'some_of', arg => '[schema*, int*, int*][]';

=head2 elems_regex => {REGEX=>SCHEMA, REGEX2=>SCHEMA2, ...]

Similar to B<elems>, but instead of specifying schema for each element, this
clause allows us to specify using regexes which elements we want to specify
schema for.

Example:

 [array, {elems_regex => {
   '[02468]$': [int => {minex=>0}],
   '[13579]$': [int => {maxex=>0}],
 }}]

The above example states that the array should have as its elements positive and
negative integer interspersed, e.g. [1, -2, 3, -1, ...].

=cut

clause 'elems_regex',
    arg     => [hash => {required=>1, keys_of=>'regex', values_of=>'schema*'}];

no Any::Moose;
1;
