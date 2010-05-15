package Data::Schema::Type::Array;
# ABSTRACT: Specification for 'array' type

=head1 DESCRIPTION

This is the specification for arrays (or arrayrefs in Perl, to be
exact).

Example schema:

 [array => {minlen => 1, maxlen => 3, elem_regex => {'.*' => 'int'} }]

The above schema says that the array must have one to three elements,
and all elements must be integers.

Example valid data:

 [1, 2]

Example invalid data:

 []          # too short
 [1,2,3,4]   # too long
 ['x']       # element not integer

=cut

use Any::Moose '::Role';
use Data::Schema::Util 'attr', 'attr_alias';
with
    'Data::Schema::Type::Base',
    'Data::Schema::Type::Comparable',
    'Data::Schema::Type::HasElement';

our $typenames = ["array"];

=head1 TYPE ATTRIBUTES

Hash assumes the following roles: L<Data::Schema::Type::Base>,
L<Data::Schema::Type::Comparable>,
L<Data::Schema::Type::HasElement>. Consult the documentation of those
role(s) to see what type attributes are available.

In addition, there are other attributes for 'array':

=head2 unique => 0 or 1

If unique is 1, require that the array values be unique (like in a
set). If unique is 0, require that there are duplicates in the array.

=cut

attr 'unique', arg => 'bool';

=head2 elements => [SCHEMA_FOR_FIRST_ELEMENT, SCHEMA_FOR_SECOND_ELEM, ...]

Aliases: B<element>, B<elems>, B<elem>

Require that each element of the array validates to the specified
schemas.

Note: filters applied by SCHEMA's to elements will be preserved.

Example:

 [array => {elements => [ 'int', 'str', [int => {min=>0}] ]}]

The above example states that the array must have an int as the first
element, string as the second, and positive integer as the third.

=cut

attr 'elements', aliases => [qw/element elems elem/], arg => 'schema[]';

=head2 of => SCHEMA

Aliases: B<all_elements>, B<all_element>, B<all_elems>, B<all_elem>

Requires that every element of the array validates to the specified
schema.

=cut

attr_alias all_element => 'of';

=head2 some_of => [[SCHEMA, MIN, MAX], [SCHEMA2, MIN, MAX], ...]

Requires that some elements validates to some schema. MIN and MAX are
numbers, -1 means unlimited.

Example:

 [array => {some_of => [
   [[int => {lt=>0}] => 1, -1],
   [[int => {gt=>0}] => 1, -1],
   [float => 3, 3],
  ]}]

The above requires that the array contains at least one positive
integer, one negative integer, exactly three floating numbers, e.g.:
[1, -1, 1.5, "str"].

=cut

attr 'some_of', arg => '[schema*, int*, int*][]';

=head2 elements_regex => {REGEX=>SCHEMA, REGEX2=>SCHEMA2, ...]

Aliases: B<element_regex>, B<elems_regex>, B<elem_regex>

Similar to B<elements>, but instead of specifying schema for each
element, this attribute allows us to specify using regexes which
elements we want to specify schema for.

Example:

 [array, {elements_regex => {
   '[02468]$': [int => {minex=>0}],
   '[13579]$': [int => {maxex=>0}],
 }}]

The above example states that the array should have as its elements
positive and negative integer interspersed, e.g. [1, -2, 3, -1, ...].

=cut

attr 'elements_regex',
    aliases => [qw/element_regex elems_regex elem_regex/],
    arg => [hash => {set=>1, keys_of=>'regex', values_of=>'schema*'}];

no Any::Moose;
1;
