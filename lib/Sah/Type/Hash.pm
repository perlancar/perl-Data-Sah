package Sah::Type::Hash;
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
use Sah::Util 'clause', 'clause_alias';
with
    'Sah::Type::Base',
    'Sah::Type::Comparable',
    'Sah::Type::HasElement';

our $type_names = ["hash"];

=head1 CLAUSES

Hash assumes the following roles: L<Sah::Type::Base>, L<Sah::Type::Comparable>,
L<Sah::Type::HasElement>. Consult the documentation of those role(s) to see what
type clauses are available.

In addition, 'hash' defines these clauses:

=cut

=head2 keys_match => REGEX

Aliases: B<allowed_keys_regex>

Require that all hash keys match a regular expression.

=cut

clause 'keys_match', alias => 'allowed_keys_regex', arg => 'regex*';

=head2 keys_not_match => REGEX

Aliases: B<forbidden_keys_regex>

This is the opposite of B<keys_match>, forbidding all hash keys from matching a
regular expression.

=cut

clause 'keys_not_match', alias => 'forbidden_keys_regex', arg => 'regex*';

=head2 keys_one_of => [VALUE, ...]

Aliases: B<allowed_keys>

Specify that all hash keys must belong to a list of specified values.

For example:

 [hash => {allowed_keys => [qw/name age address/]}]

This specifies that only keys 'name', 'age', 'address' are allowed (but none are
required).

=cut

clause 'keys_one_of', alias => 'allowed_keys', arg => '((str*)[])*';

=head2 values_one_of => [VALUE, ...]

Aliases: B<allowed_values>

Specify that all hash values must belong to a list of specified values.

For example:

 [hash => {allowed_values => [1, 2, 3, 4, 5]}]

=cut

clause 'values_one_of', alias => 'allowed_values', arg => '((any*)[])*';

=head2 required_keys => [KEY1, KEY2. ...]

Require that certain keys exist in the hash.

=cut

clause 'required_keys', arg => '((str*)[])*';

=head2 required_keys_regex => REGEX

Require that at least one key matches a regular expression (but its value is not
required).

=cut

clause 'required_keys_regex', arg => 'regex*';

=head2 keys => {KEY=>SCHEMA1, KEY2=>SCHEMA2, ...}

Specify schema for each hash key (hash value, actually). All hash keys must match
one of the keys specified in this clause (unless B<allow_extra_keys> is true).

Note: filters applied by SCHEMA's to hash values will be preserved.

For example:

 [hash => {keys => { name => 'str*', age => ['int*', {min=>0}] } }]

This specifies that the value for key 'name' must be a string, and the value for
key 'age' must be a positive integer.

Note: if you want to specify a single schema for all keys, use B<keys_of>.

=cut

clause 'keys', arg => '{*=>schema*}*';

=head2 keys_of => SCHEMA

Aliases: B<all_keys>

Specify a schema for all hash keys.

For example:

 [hash => {keys_of => 'int'}]

This specifies that all hash keys must be ints.

See also: B<values_of>

=cut

clause 'keys_of', alias => 'all_keys', arg => 'schema*';

=head2 of => SCHEMA

Aliases: B<all_values>, B<values_of>, B<all_elements>, B<all_elems>, B<all_elem>

Specify a schema for all hash values.

Note: filters applied by SCHEMA to pair values will be preserved.

For example:

 [hash => {of => 'int'}]

This specifies that all hash values must be ints.

=cut

clause_alias all_elements => [qw/of all_values values_of/];

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

clause 'some_of',
    arg => ['array*' => {of => ['array*' => {elements => [
        'schema*',
        'schema*',
        ['int*', {ge=>-1}],
        ['int*', {ge=>-1}],
    ]}]}];


=head2 keys_regex => {REGEX1=>SCHEMA1, REGEX2=>SCHEMA2, ...}

Similar to B<keys> but instead of specifying schema for each key, we specify
schema for each set of keys using regular expression. All hash keys must match at
least one regex specified.

For example:

 [hash=>{keys_regex=>{ '\d'=>"int", '^\D+$'=>"str" }}]

This specifies that for all keys which contain a digit, the values must be int,
while for all non-digit-containing keys, the values must be str. Example: {
a=>"a", a1=>1, a2=>-3, b=>1 }. Note: b=>1 is valid because 1 is a valid str. Note
that keys like '' (empty string) will also fail because it matches none of the
regexes specified (you can change this by adding B<allow_extra_keys>=1).

This clause also obeys B<allow_extra_keys> setting, like C<keys>.

Example:

Given schema [hash=>{keys_regex=>{'^\w+$'=>[str=>{match=>'^\w+$'}]}}], data {foo
=> bar, "contain space" => "contain space"} is invalid because there is a key
that doesn't match the regex.

Given schema [hash=>{allow_extra_keys=>1,
keys_regex=>{'^\w+$'=>[str=>{match=>'^\w+$'}]}}], the same data will be valid
because extra keys are allowed.

=cut

clause 'keys_regex',
    arg => ['hash*', {keys_of=>'regex*', values_of=>'schema*'}];

=head2 values_match => REGEX

Aliases: B<allowed_values_regex>

Specifies that all values must be scalar and match regular expression.

=cut

clause 'values_match', alias => 'allowed_values_regex', arg => 'schema*';

=head2 values_not_match => REGEX

Aliases: B<forbidden_values_regex>

The opposite of B<values_match>, requires that all values not match regular
expression (but must be a scalar).

=cut

clause 'values_not_match', alias => 'forbidden_values_regex', arg => 'schema*';

=head2 key_deps => SCHEMA

Aliases: B<key_dep>, B<element_deps>, B<elem_deps>, B<element_dep>, B<elem_dep>

Specify inter-element dependency. This is actually just an alias to
B<element_deps>. See L<Sah::Type::HasElement> for details.

=cut

clause_alias element_deps => [qw/key_deps key_dep/];

=head2 allow_extra_keys => BOOL

This is a setting which is observed by B<keys> and B<keys_regex>. Default is 0,
meaning no extra keys allowed and all possible keys must be specified in B<keys>
and/or B<keys_regex>.

When this setting is true, all keys not matching B<keys> and B<keys_regex> are
allowed (unless they disobey B<allowed_keys>/B<forbidden_keys> or other
clauses).

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

Using B<allow_extra_keys> is not recommended unless really necessary, as it can
cause typos in hash keys to be left undetected (e.g. data is {neighbor: "a"} and
schema is [hash=>{keys=>{neighbour=>'int', allow_extra_keys=>1}}]. In this case,
the "neighbor" key is just regarded as an extra key thus ignored).

=cut

clause 'allow_extra_keys', prio => 49, arg => 'bool*';

=head2 ignore_keys => [STR, ...]

By default, using B<keys> and B<keys_regex>, you have to specify all possible
keys to validate (except when using B<allow_extra_keys>). This clause allows
you to exempt some keys. Example:

 [hash => {keys => {a => "int", b => "int"}, ignore_keys => ["c"]}]

This means only keys C<a> and C<b> are allowed in hash and the values must be
integers. C<d> etc will not validate. But C<c> will because it's ignored.

=cut

clause 'ignore_keys', prio => 49, arg => '((str*)[])*';

=head2 ignore_keys_regex => REGEX

Just like B<ignore_keys>, except you specify keys to be ignored via a regex.

=cut

clause 'ignore_keys_regex', prio => 49, arg => 'regex*';

=head2 conflicting_keys => [[A, B], [C, D, E], ...]

State that A and B are conflicting keys and cannot exist together. And so are C,
D, E.

Example:

Given schema [hash=>{conflicting_keys=>[["C", "D", "E"]]}], data {C=>1} is valid
but {C=>1, D=>1} or {C=>1, D=>1, E=>1} is not.

=cut

clause 'conflicting_keys', arg => '((((str*)[])*)[])*';

=head2 conflicting_keys_regex => [[REGEX_A, REGEX_B], [REGEX_C, REGEX_D, REGEX_E], ...]

Just like C<conflicting_keys>, but keys are expressed using regular expression.

=cut

clause 'conflicting_keys_regex', arg => '((((regex*)[])*)[])*';

=head2 codependent_keys => [[A, B], [C, D, E], ...]

State that A and B are codependent keys and must exist together. And so are C, D,
E.

Given schema [hash=>{codependent_keys=>[["C", "D", "E"]]}], data {C=>1, D=>1} is
not valid but {C=>1, D=>1, E=>1} is.

=cut

clause 'codependent_keys', arg => '((((str*)[])*)[])*';

=head2 codependent_keys_regex => [[REGEX_A, REGEX_B], [REGEX_C, REGEX_D, REGEX_E], ...]

Just like C<codependent_keys>, but keys are expressed using regular expression.

=cut

clause 'codependent_keys_regex', arg => '((((regex*)[])*)[])*';

=head2 values_unique => 1|0|undef

If 1, require that the hash values be unique. If 0, require that there are
duplicates in the hash values.

=cut

clause 'values_unique', arg => 'bool';

no Any::Moose;
1;
