package Data::Schema::Func::Std;
# ABSTRACT: Specification for standard functions in Data::Schema

=head1 DESCRIPTION

This is the specification for standard functions in Data::Schema. Most
of them follow rather closely to functions in Perl.

Functions in Data::Schema will be converted to actual functions by
emitters.

When used as filters, if passed an inappropriate argument, the
function will do nothing (pass the first argument through unchanged).

=cut

use Any::Moose '::Role';
use Data::Schema::Util 'func', 'func_alias';

=head1 FUNCTIONS

=cut

=head2 abs(float) -> float

Return absolute value.

=cut

func 'abs', args => ['float*'], return => 'float*';

=head2 add(array) -> float

Add arguments mathematically. Used internally to implement the C<+>
and C<-> operator. See also: B<multiply>, B<divide>, B<negative>.

Example:

 add([4, 5, -1]) # 8

=cut

func 'add', args => ['array*'], return => 'float*';

=head2 atan2(y, x) -> float

Return the arctangent of y/x.

=cut

func 'atan2', args => ['float*', 'float*'], return => 'float*';

=head2 ceil(float|str) -> int

Return the smallest integer equals to or larger than float. See also:
B<floor>.

=cut

func 'ceil', args => ['str*'], return => 'int*';

=head2 chomp(str) -> str

Remove a single trailing newline from string, if exists. If you want
to remove all trailing newlines, you can use:

 re_replace('\n+$', '', str)

=cut

func 'chomp', args => ['str*'], return => 'str*';

=head2 cirsort(array) -> array

Like cisort(), but in reverse order. See also: the other *sort() functions.

=cut

func 'cirsort', args => ['array*'], return => 'array*';

=head2 cisort(array) -> array

Sort an array asciibetically and case-insensitively. See also:
B<cisort> and the other *sort() functions.

=cut

func 'cisort', args => ['array*'], return => 'array*';

=head2 cos(float) -> float

Return the cosine of number (expressed in radians).

=cut

func 'cos', args => ['float*'], return => 'float*';

=head2 count(array|hash) -> int

Return the number of elements of an array, or the number of key=>value
pairs of a hash.

=cut

func 'count', args => ['array|hash'], return => 'int';

=head2 defined(any) -> bool

Return true if value is defined, false otherwise. See also: B<typeof>.

=cut

func 'defined', args => ['any'], return => 'bool*';

=head2 divide(array) -> float

Divide its arguments mathematically. Used internally to implement the
C</> operator. See also: B<multiply>, B<add>, B<negative>.

Example:

 divide([24, 3, 4]) # 2

=cut

func 'divide', args => ['array*'], return => 'float*';

=head2 element(array|hash) -> any

Access element of array/hash. Used internally to implement the C<[]>
operator.

Example:

 element(["a", "b", "c"], 1) # b

=cut

func 'element', args => ['array|hash', 'str'], return => 'any';

=head2 exists(hash, str) -> bool

Return true if hash contains certain key.

=cut

func 'exists', args => ['hash*', 'str*'], return => 'bool*';

=head2 exp(float) -> float

Return e (the natural logarithm base) to the power of float.

=cut

func 'exp', args => ['float*'], return => 'float*';

=head2 flip(array) -> array

Reverse an array (first element becomes last, second element becomes
second last, and so on). See also: B<reverse>, B<invert>.

Example:

 flip([1, 2, 3]) # [3, 2, 1]

=cut

func 'flip', args => ['array*'], array => 'array*';

=head2 float(str) -> float

Convert string to float, or undef if fails.

=cut

func 'float', args => ['str*'], return => 'float';

=head2 floor(float|str) -> int

Return the largest integer equals or less to float. See also: B<ceil>.

=cut

func 'floor', args => ['str*'], return => 'int*';

=head2 hex(str) -> int

Interpret str as hexadecimal and return the corresponding value.

=cut

func 'hex', args => ['str*'], return => 'int*';

=head2 if(bool, any1, any2) -> any

If bool is true, return any1, else return any2.

=cut

func 'if', args => ['bool*', 'any', 'any'], return => 'any';

=head2 index(str|array, any) -> int

Return the first index of a string/array which contains the second
argument. Return undef if not found. See also: B<rindex>.

=cut

func 'index', args => ['str|array'], return => 'int';

=head2 invert(hash) -> hash

Invert a hash (switch key and value). See also: B<reverse>, B<flip>.

 invert({a=>1, b=>1, c=>2}) # {1=>b, 2=>c}

=cut

func 'invert', args => ['hash*'], return => 'hash*';

=head2 join(str, array) -> str

Join array together with str as separator. See also: B<split>.

=cut

func 'join', args => ['str*', 'array*'], return => 'str*';

=head2 log(float) -> float

Return the natural logarithm (base e) of argument.

=cut

func 'log', args => ['float*'], return => 'float*';

=head2 keys(hash) -> array

Return an array of hash keys. See also: B<values>.

=cut

func 'keys', args => ['hash*'], return => 'array*';

=head2 lc(str) -> str

Convert string to lowercase. See also: B<lcfirst>, B<uc>.

=cut

func 'lc', args => ['str*'], return => 'str*';

=head2 length(str) -> int

Return the length of string, or undef if str is undef.

=cut

func 'length', args => ['str'], return => 'str';

=head2 ltrim(str) -> str

Remove leading blanks from str. See also: B<rtrim>, B<trim>.

=cut

func 'ltrim', args => ['str*'], return => 'str*';

=head2 multiply(array) -> float

Multiply arguments mathematically. Used internally to implement the
C<*> operator. See also: B<divide>, B<add>, B<negative>.

Example:

 multiply([2, 3, 4]) # 24

=cut

func 'multiply', args => ['array*'], return => 'float*';

=head2 negative(float) -> float

Return the negative of argument. Used internally to implement the unary
C<-> operator.

Example:

 negative(8) # -8

=cut

func 'negative', args => ['any*'], return => 'float*';

=head2 nrsort(array) -> array

Like nsort(), but in reverse order. See also: the other *sort()
functions.

=cut

func 'nrsort', args => ['array*'], return => 'array*';

=head2 nsort(array) -> array

Sort an array numerically. See also: B<nrsort> and the other *sort()
functions.

=cut

func 'nsort', args => ['array*'], return => 'array*';

=head2 oct(str) -> int

Interpret str as octal and return the corresponding value.

=cut

func 'oct', args => ['str*'], return => 'int*';

=head2 pow(float_a, float_b) -> float

Return a powered to b.

=cut

func 'pow', args => ['float*', 'float*'], return => 'float*';

=head2 rand() -> float

Return a random floating point between 0 and 1.

=cut

func 'rand', args => [], return => 'float*';

=head2 re_replace(regex, str_replacement, str) -> str

Replace string using regex. See also: B<re_replace_once>.

=cut

func 're_replace', args => ['regex*', 'str*', 'str*'], return => 'str*';

=head2 re_replace_once(regex, str_replacement, str) -> str

Like B<re_replace>, but only replace the first occurence of match.

=cut

func 're_replace_once', args => ['regex*', 'str*', 'str*'], return => 'str*';

=head2 reverse(str) -> str

Reverse a string (first character becomes last, second character becomes
second last, and so on). See also: B<flip>, B<invert>.

Example:

 reverse("abc") # "cba"

=cut

func 'reverse', args => ['str*'], return => 'str*';

=head2 rindex(str|array, any) -> int

Just like index() but search from the last position to the first.

=cut

func 'rindex', args => ['str|array'], return => 'int';

=head2 rsort(array) -> array

Like sort(), but in reverse order. See also: the other *sort()
functions.

=cut

func 'rsort', args => ['array*'], return => 'array*';

=head2 rtrim(str) -> str

Remove trailing blanks from str. See also: B<ltrim>, B<trim>.

=cut

func 'rtrim', args => ['str*'], return => 'str*';

=head2 sine(float) -> float

Return the sine of number (expressed in radians).

=cut

func 'sin', args => ['float*'], return => 'float*';

=head2 sort(array) -> array

Sort an array asciibetically. See also: B<rsort> and the other *sort()
functions.

=cut

func 'sort', args => ['array*'], return => 'array*';

=head2 split(regex, str[, int_limit]) -> array

Split string into array. Optional third argument limits the number of
elements to split into. See also: B<join>.

=cut

func 'split', args => ['regex*', 'str*', 'int'], return => 'array*';

=head2 sqrt(float) -> float

Return the square root of argument, equivalent to power(float, 0.5).

=cut

func 'sqrt', args => ['float*'], return => 'float';

=head2 substr(str, int_start[, int_len]) -> str

Return substring, from int_start position (start of string is 0, can
be negative to count from end of string), int_len is optional can by
default means for the rest of the string.

=cut

func 'substr', args => ['str*', 'int*', 'int'], return => 'str*';

=head2 trim(str) -> str

Remove leading and trailing blanks from str. See also: B<ltrim>, B<rtrim>.

=cut

func 'trim', args => ['str*'], return => 'str*';

=head2 typeof(any) -> str

Return the type of argument, either "undef", "str", "bool", "array",
or "hash". See also: B<defined>.

=cut

func 'typeof', args => ['any'], return => 'str*';

=head2 uc(str) -> str

Convert string to uppercase. See also: B<lc>, B<ucfirst>.

=cut

func 'uc', args => ['str*'], return => 'str*';

=head2 ucfirst(str) -> str

Convert first character of string to uppercase. See also: B<lc>, B<ucfirst>.

=cut

func 'ucfirst', args => ['str*'], return => 'str*';

=head2 values(hash) -> array

Return an array of hash values. See also: <keys>.

=cut

func 'values', args => ['hash*'], return => 'array*';

# TODO:
# str: remove_nondigit
# str: remove_whitespace
# str: remove_nonalpha
# str: remove_nonalphanum
# str: parse_float
# str: parse_int
# hash: convert into array?
# hash: clean/remove undef values, false values, empty values, empty hashes, non hashes, pairs that do not match certain regex, etc
# array: grep: clean/remove undef elements, false elements, empty elements, empty arrays, non arrays
# array: pick
# array: convert into hash
# array: map
# array: usort (using custom function)
# date: parse_date
# date: date_format
# date: date arithmetics

no Any::Moose;
1;
