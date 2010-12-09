package Sah::Type::HasElement;
# ABSTRACT: Specification for types that have the notion of elements

=head1 DESCRIPTION

This is the role for types that have the notion of length. It provides clauses
like B<maxlen>, B<length>, B<length_between>, B<all_elements>, etc. It is used by
'array', 'hash', and also 'str'.

Role consumer must provide method 'metaclause_has_element' which will receive the
same %args as clause methods, but with additional key: -which (either 'max_len',
'min_len', 'len', 'len_between', 'contains_one', 'contains_all', 'contains_none',
'contains', 'not_contains').

=cut

use Any::Moose '::Role';
use Sah::Util 'clause';

requires 'metaclause_has_element';

=head1 CLAUSES

=head2 max_len => LEN

Aliases: B<maxlen>, B<max_length>, B<maxlength>

Requires that the data have at most LEN elements.

=cut

clause 'max_len',
    aliases => [qw/maxlen max_length maxlength/],
    arg     => ['int*' => {ge=>0}],
    code    => sub {
        my ($self, %args) = @_;
        $self->metaclause_has_element(%args, -which => 'max_len');
    };

=head2 min_len => LEN

Aliases: B<minlen>, B<min_length>, B<minlength>

Requires that the data have at least LEN elements.

=cut

clause 'min_len',
    aliases => [qw/minlen min_length minlength/],
    arg     => ['int*' => {ge=>0}],
    code    => sub {
        my ($self, %args) = @_;
        $self->metaclause_has_element(%args, -which => 'min_len');
    };

=head2 len_between => [MIN, MAX]

Aliases: B<length_between>

A convenience clause that combines B<minlen> and B<maxlen>.

=cut

clause 'len_between',
    alias => 'length_between',
    arg   => ['array*' => {elements => ['int*', 'int*']}],
    code  => sub {
        my ($self, %args) = @_;
        $self->metaclause_has_element(%args, -which => 'len_between');
    };

=head2 len => LEN

Aliases: B<length>

Requires that the data have exactly LEN elements.

=cut

clause 'len',
    alias => 'length',
    arg   => ['int*' => {gt=>0}],
    code  => sub {
        my ($self, %args) = @_;
        $self->metaclause_has_element(%args, -which => 'len');
    };

=head2 contains_all => [ELEM, ...]

Aliases: B<contain_all>

Requires that the data contain all the elements.

=cut

clause 'contains_all',
    aliases => [qw/contain_all/],
    arg => '(any[])*',
    code => sub {
        my ($self, %args) = @_;
        $self->metaclause_has_element(%args, -which => 'contains_all');
    };

=head2 contains_none => [ELEM, ...]

Aliases: B<contain_none>

Requires that the data contain none of the elements.

=cut

clause 'contains_none',
    aliases => [qw/contain_none/],
    arg => '(any[])*',
    code => sub {
        my ($self, %args) = @_;
        $self->metaclause_has_element(%args, -which => 'contains_none');
    };

=head2 contains_one => [ELEM, ...]

Aliases: B<contain_one>

Requires that the data contain at least one of the elements.

=cut

clause 'contains_one',
    aliases => [qw/contain_one/],
    arg => '(any[])*',
    code => sub {
        my ($self, %args) = @_;
        $self->metaclause_has_element(%args, -which => 'contains_one');
    };

=head2 contains => ELEM

Aliases: B<contain>

Requires that the data contain the elements. This is a shortcut to contains_all
=> [ELEM].

=cut

clause 'contains',
    aliases => [qw/contain/],
    arg => 'any*',
    code => sub {
        my ($self, %args) = @_;
        $self->metaclause_has_element(%args, -which => 'contains');
    };

=head2 not_contains => ELEM

Aliases: B<not_contain>

Requires that the data not contain the elements. This is a shortcut to
contains_none => [ELEM].

=cut

clause 'not_contains',
    aliases => [qw/not_contain/],
    arg => 'any*',
    code => sub {
        my ($self, %args) = @_;
        $self->metaclause_has_element(%args, -which => 'not_contains');
    };

=head2 all_elements => SCHEMA

Aliases: B<all_element>, B<all_elems>, B<all_elem>

Requires that every element of the data validate to the specified schema.

Note: filters applied by SCHEMA to elements will be preserved.

Examples:

 [array => {all_elements => 'int'}]

The above specifies an array of ints.

 [hash => {all_elements => [str => { match => '^[A-Za-z0-9]+$' }]}]

The above specifies hash with alphanumeric-only values.

=cut

clause 'all_elements',
    aliases => [qw/all_element all_elems all_elem/],
    arg => 'schema*',
    code => sub {
        my ($self, %args) = @_;
        $self->metaclause_has_element(%args, -which => 'all_elements');
    };

=head2 element_deps => [[REGEX1 => SCHEMA1, REGEX1 => SCHEMA2], ...]

Aliases: B<element_dep>, B<elem_deps>, B<elem_dep>

Specify inter-element dependencies. If all elements at indexes which match REGEX1
match SCHEMA1, then all elements at indexes which match REGEX2 must match
SCHEMA2.

Examples:

 [hash => {elem_deps => [
   [ password => 'str*', password_confirmation => 'str*' ]
 ]}]

The above says: key 'password_confirmation' is required if 'password' is set.

 [hash => {elem_deps => [
   [ province => ['str*', {is => 'Outside US'}],
     zipcode => [str => {set=>0}] ],
   [ province => ['str*', {not => 'Outside US'}],
     zipcode => [str => {set=>1}] ]
 ]}]

The above says: if province is set to 'Outside US', then zipcode must not be
specified. Otherwise if province is set to US states, zipcode is required.

 [array => {elem_deps => [
     [ '^0$',   ['str*'  => {one_of => ['int', 'integer']}],
       '[1-9]', ['hash*' => {allowed_keys => [qw/is not min max/]}] ],
     [ '^0$',   ['str*'  => {one_of => ['str', 'string']}],
       '[1-9]', ['hash*' => {allowed_keys => [qw/is not min max minlen maxlen/]}] ],
     [ '^0$',   ['str*'  => {one_of => ['bool', 'boolean']}],
       '[1-9]', ['hash*' => {allowed_keys => [qw/is not/]}] ],
 ]}]

The above says: if first element of array is a text with value 'int'/'integer',
then the following elements must be hash with specified keys. A similar rule is
there for first element being 'str'/'string' and 'bool'/'boolean'.

Example valid array:

 ['str', {minlen=>0, maxlen=>1}, {is=>'a', not=>'b'}]

Example invalid array (key 'minlen' is not allowed):

 ['int', {minlen=>0, maxlen=>1}, {is=>'a', not=>'b'}]

Note: You need to be careful with undef, because it matches all schema unless
set=>1/required=>1 (or the shortcut 'foo*') is specified.

=cut

clause 'element_deps',
    aliases => [qw/element_dep elem_deps elem_dep/],
    arg => '([regex, schema*, regex, schema*][])*',
    code => sub {
        my ($self, %args) = @_;
        $self->metaclause_has_element(%args, -which => 'element_deps');
    };

no Any::Moose;
1;
