package Data::Schema::Spec::v10::Type::Hash;
# ABSTRACT: Specification for 'hash' type

=head1 DESCRIPTION

This is the specification for 'hash' type.

Example schema:

 [hash => {
    required_keys => [qw/name age/],
    allowed_keys => [qw/name age note/],
    keys => {
      name => 'str*',
      age => [int => {min => 0}],
    }
 }]

Example valid data:

 {name => 'Lisa', age => 14, note => "Bart's sister"}
 {name => 'Lisa', age => undef}

Note for the second example: according to the schema, 'name' and 'age' keys are
required to exist. But value of 'age' is not required, while value of 'name' is
required.

Example invalid data:

 []                                      # not a hash
 {name => 'Lisa'}                        # doesn't have the required key: age
 {name => 'Lisa', age => -1}             # age must be positive integer
 {name => 'Lisa', age => 14, sex => 'F'} # sex is not in list of allowed keys

Another example:

 # keys must be variable names, value must be string and defined
 [hash => {keys_of   => [str => {match=>'/^\w+$/'}],
           values_of => 'str*'}]

=cut

use Any::Moose '::Role';
use Data::Schema::Util 'attr', 'attr_alias';
with
    'Data::Schema::Spec::v10::Type::Base',
    'Data::Schema::Spec::v10::Type::Comparable',
    'Data::Schema::Spec::v10::Type::HasElement';

our $typenames = ["hash"];

=head1 TYPE ATTRIBUTES

Hash assumes the following roles: L<Data::Schema::Spec::v10::Type::Base>,
L<Data::Schema::Spec::v10::Type::Comparable>,
L<Data::Schema::Spec::v10::Type::HasElement>. Consult the documentation of those
role(s) to see what type attributes are available.

In addition, 'hash' defines these attributes:

=cut

=head2 keys_match => REGEX

Aliases: B<allowed_keys_regex>

Require that all hash keys match a regular expression.

=cut

attr 'keys_match', alias => 'allowed_keys_regex', arg => 'regex*';

=head2 keys_not_match => REGEX

Aliases: B<forbidden_keys_regex>

This is the opposite of B<keys_match>, forbidding all hash keys from matching a
regular expression.

=cut

attr 'keys_not_match', alias => 'forbidden_keys_regex', arg => 'regex*';

=head2 keys_one_of => [VALUE, ...]

Aliases: B<allowed_keys>

Specify that all hash keys must belong to a list of specified values.

For example:

 [hash => {allowed_keys => [qw/name age address/]}]

This specifies that only keys 'name', 'age', 'address' are allowed (but none are
required).

=cut

attr 'keys_one_of', alias => 'allowed_keys', arg => '((str*)[])*';

=head2 values_one_of => [VALUE, ...]

Aliases: B<allowed_values>

Specify that all hash values must belong to a list of specified values.

For example:

 [hash => {allowed_values => [1, 2, 3, 4, 5]}]

=cut

attr 'values_one_of', alias => 'allowed_values', arg => '((any*)[])*';

=head2 required_keys => [KEY1, KEY2. ...]

Require that certain keys exist in the hash.

=cut

attr 'required_keys', arg => '((str*)[])*';

=head2 required_keys_regex => REGEX

Require that at least one key matches a regular expression (but its value is not
required).

=cut

attr 'required_keys_regex', arg => 'regex*';

=head2 keys => {KEY=>SCHEMA1, KEY2=>SCHEMA2, ...}

Specify schema for hash keys (hash values, actually).

Note: filters applied by SCHEMA's to hash values will be preserved.

For example:

 [hash => {keys => { name => 'str*', age => ['int*', {min=>0}] } }]

This specifies that the value for key 'name' must be a string, and the value for
key 'age' must be a positive integer.

Note: if you want to specify a schema for all keys, use B<keys_of>.

=cut

attr 'keys', arg => '{*=>schema*}*';

=head2 keys_of => SCHEMA

Aliases: B<all_keys>

Specify a schema for all hash keys.

For example:

 [hash => {keys_of => 'int'}]

This specifies that all hash keys must be ints.

See also: B<values_of>

=cut

attr 'keys_of', alias => 'all_keys', arg => 'schema*';

=head2 of => SCHEMA

Aliases: B<all_values>, B<values_of>, B<all_elements>, B<all_elems>, B<all_elem>

Specify a schema for all hash values.

Note: filters applied by SCHEMA to pair values will be preserved.

For example:

 [hash => {of => 'int'}]

This specifies that all hash values must be ints.

=cut

attr_alias all_elements => [qw/of all_values values_of/];

=head2 some_of => [[KEY_SCHEMA, VALUE_SCHEMA, MIN, MAX], [KEY_SCHEMA2, VALUE_SCHEMA2, MIN2, MAX2], ...]

Requires that some elements matches schema. MIN and MAX are numbers, -1 means
unlimited.

Example:

 [hash => {some_of => [[
   ['str*' => {one_of => [qw/userid username email/]}],
   'str*',
   1, 1
 ]]}]

The above requires that the hash has *either* 'userid', 'username', or 'email'
key specified but not both or three of them. In other words, the hash has to
choose to specify only one of the three.

=cut

attr 'some_of',
    arg => ['array*' => {of => ['array*' => {elements => [
        'schema*',
        'schema*',
        ['int*', {ge=>-1}],
        ['int*', {ge=>-1}],
    ]}]}];


=head2 keys_regex => {REGEX1=>SCHEMA1, REGEX2=>SCHEMA2, ...}

Similar to B<keys> but instead of specifying schema for each key, we specify
schema for each set of keys using regular expression.

For example:

 [hash=>{keys_regex=>{ '\d'=>"int", '^\D+$'=>"str" }}]

This specifies that for all keys which contain a digit, the values must be int,
while for all non-digit-containing keys, the values must be str. Example: {
a=>"a", a1=>1, a2=>-3, b=>1 }. Note: b=>1 is valid because 1 is a valid str.

This attribute also obeys B<allow_extra_keys> setting, like C<keys>.

Example:

 # invalid, no rule in keys_regex matches
 ds_validate({"contain space" => "contain space"},
             [hash=>{keys_regex=>{'^\w+$'=>[str=>{match=>'^\w+$'}]}}]);

 # valid
 ds_validate({"contain space" => "contain space"},
             [hash=>{allow_extra_keys=>1,
                     keys_regex=>{'^\w+$'=>[str=>{match=>'^\w+$'}]}}]);

=cut

attr 'keys_regex',
    arg => ['hash*', {keys_of=>'regex*', values_of=>'schema*'}];

=head2 values_match => REGEX

Aliases: B<allowed_values_regex>

Specifies that all values must be scalar and match regular expression.

=cut

attr 'values_match', alias => 'allowed_values_regex', arg => 'schema*';

=head2 values_not_match => REGEX

Aliases: B<forbidden_values_regex>

The opposite of B<values_match>, requires that all values not match regular
expression (but must be a scalar).

=cut

attr 'values_not_match', alias => 'forbidden_values_regex', arg => 'schema*';

=head2 key_deps => SCHEMA

Aliases: B<key_dep>, B<element_deps>, B<elem_deps>, B<element_dep>, B<elem_dep>

Specify inter-element dependency. This is actually just an alias to
B<element_deps>. See L<Data::Schema::Spec::v10::Type::HasElement> for details.

=cut

attr_alias element_deps => [qw/key_deps key_dep/];

=head2 allow_extra_keys => BOOL

This is a setting which is observed by B<keys> and B<keys_regex>. Default is 0.
If true, then all keys must be specified in B<keys> and B<keys_regex>. It
effectively adds an B<allowed_keys> attribute containing all keys specified in
B<keys>. For example, the two address schemas below are equivalent.

 # 'address' schema, using style allow_extra_keys => 1
 [hash => {
   allow_extra_keys => 1,
   allowed_keys => [qw/line1 line2 city province country postcode/],
   keys => {
     line1 => 'str*',
     line2 => 'str',
     city => 'str*',
     province => 'str*',
     country => ['str*', {match => '^[A-Z]{2}$'}],
     postcode => 'str',
   }
 }]

 # 'address' schema, using style allow_extra_keys => 0
 [hash => {
   keys => {
     line1 => 'str*',
     line2 => 'str',
     city => 'str*',
     province => 'str*',
     country => ['str*', {match => '^[A-Z]{2}$'}],
     postcode => 'str',
   }
 }]

 # 'us_address' schema
 ['address*' => {
   allow_extra_keys => 1,
   keys =>
     country => ['str*' => {is => 'US'}]
 }]

Without allow_extra_keys set to 1, 'us_address' will only allow key 'country'
(due to 'keys' limiting allowed hash keys to only those specified in it).

=cut

attr 'allow_extra_keys', prio => 10, arg => 'bool*';

=head2 conflicting_keys => [[A, B], [C, D, E], ...]

State that A and B are conflicting keys and cannot exist together. And so are C,
D, E.

Example:

 ds_validate({C=>1      }, [hash=>{conflicting_keys=>[["C", "D", "E"]]}]); # valid
 ds_validate({C=>1, D=>1}, [hash=>{conflicting_keys=>[["C", "D", "E"]]}]); # invalid

=cut

attr 'conflicting_keys', arg => '((((str*)[])*)[])*';

=head2 conflicting_keys_regex => [[REGEX_A, REGEX_B], [REGEX_C, REGEX_D, REGEX_E], ...]

Just like C<conflicting_keys>, but keys are expressed using regular expression.

=cut

attr 'conflicting_keys_regex', arg => '((((regex*)[])*)[])*';

=head2 codependent_keys => [[A, B], [C, D, E], ...]

State that A and B are codependent keys and must exist together. And so are C, D,
E.

Example:

 ds_validate({C=>1, D=>1      }, [hash=>{codependent_keys=>[["C", "D", "E"]]}]); # invalid
 ds_validate({C=>1, D=>1, E=>1}, [hash=>{codependent_keys=>[["C", "D", "E"]]}]); # valid

=cut

attr 'codependent_keys', arg => '((((str*)[])*)[])*';

=head2 codependent_keys_regex => [[REGEX_A, REGEX_B], [REGEX_C, REGEX_D, REGEX_E], ...]

Just like C<codependent_keys>, but keys are expressed using regular expression.

=cut

attr 'codependent_keys_regex', arg => '((((regex*)[])*)[])*';

=head2 values_unique => 1|0|undef

If 1, require that the hash values be unique. If 0, require that there are
duplicates in the hash values.

=cut

attr 'values_unique', arg => 'bool';

no Any::Moose;
1;
