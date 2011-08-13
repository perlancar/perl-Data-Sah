package Data::Sah::Type::HasElems;
# ABSTRACT: Specification for types that have the notion of elements

=head1 DESCRIPTION

This is the role for types that have the notion of elements/length. It provides
clauses like B<max_len>, B<len>, B<len_between>, B<all_elems>, etc. It is used
by 'array', 'hash', and also 'str'.

Role consumer must provide method 'superclause_has_element' which will receive
the same %args as clause methods, but with additional key: -which (either
'max_len', 'min_len', 'len', 'len_between', 'has_any', 'has_all', 'has_none',
'has', 'hasnt').

=cut

use Moo::Role;
use Data::Sah::Util 'clause';

requires 'superclause_has_elems';

=head1 CLAUSES

=head2 max_len => LEN

Requires that the data have at most LEN elements.

=cut

clause 'max_len',
    arg     => ['int*' => {min=>0}],
    code    => sub {
        my ($self, %args) = @_;
        $self->superclause_has_elems(%args, -which => 'max_len');
    };

=head2 min_len => LEN

Requires that the data have at least LEN elements.

=cut

clause 'min_len',
    arg     => ['int*' => {min=>0}],
    code    => sub {
        my ($self, %args) = @_;
        $self->superclause_has_elems(%args, -which => 'min_len');
    };

=head2 len_between => [MIN, MAX]

A convenience clause that combines B<min_len> and B<max_len>.

=cut

clause 'len_between',
    arg   => ['array*' => {elements => ['int*', 'int*']}],
    code  => sub {
        my ($self, %args) = @_;
        $self->superclause_has_elems(%args, -which => 'len_between');
    };

=head2 len => LEN

Requires that the data have exactly LEN elements.

=cut

clause 'len',
    arg   => ['int*' => {minex=>0}],
    code  => sub {
        my ($self, %args) = @_;
        $self->superclause_has_elems(%args, -which => 'len');
    };

=head2 has_all => [ELEM, ...]

Requires that the data has all the elements.

=cut

clause 'has_all',
    arg => '(any[])*',
    code => sub {
        my ($self, %args) = @_;
        $self->superclause_has_elems(%args, -which => 'has_all');
    };

=head2 has_any => [ELEM, ...]

Requires that the data contain any of the elements.

=cut

clause 'has_any',
    arg => '(any[])*',
    code => sub {
        my ($self, %args) = @_;
        $self->superclause_has_elems(%args, -which => 'has_any');
    };

=head2 has_none => [ELEM, ...]

Requires that the data contain none of the elements.

=cut

clause 'has_none',
    aliases => [qw/has_none/],
    arg => '(any[])*',
    code => sub {
        my ($self, %args) = @_;
        $self->superclause_has_elems(%args, -which => 'has_none');
    };

=head2 has => ELEM

Requires that the data contain the element

=cut

clause 'has',
    arg => 'any',
    code => sub {
        my ($self, %args) = @_;
        $self->superclause_has_elems(%args, -which => 'has');
    };

=head2 hasnt => ELEM

Requires that the data not contain the element

=cut

clause 'hasnt',
    arg => 'any',
    code => sub {
        my ($self, %args) = @_;
        $self->superclause_has_elems(%args, -which => 'hasnt');
    };

=head2 all_elems => SCHEMA

Requires that every element of the data validate to the specified schema.

Note: filters applied by SCHEMA to elements will be preserved.

Examples:

 [array => {all_elems => 'int'}]

The above specifies an array of ints.

 [hash => {all_elems => [str => { match => '^[A-Za-z0-9]+$' }]}]

The above specifies hash with alphanumeric-only values.

=cut

clause 'all_elems',
    arg => 'schema*',
    code => sub {
        my ($self, %args) = @_;
        $self->superclause_has_elems(%args, -which => 'all_elems');
    };

=head2 elem_deps => [[REGEX1 => SCHEMA1, REGEX1 => SCHEMA2], ...]

Specify inter-element dependencies. If all elements at indexes which match
REGEX1 match SCHEMA1, then all elements at indexes which match REGEX2 must match
SCHEMA2.

Examples:

 [hash => {elem_deps => [
   [ password => 'str*', password_confirmation => 'str*' ]
 ]}]

The above says: key 'password_confirmation' is required if 'password' is set.

 [hash => {elem_deps => [
   [ province => ['str*', {is => 'Outside US'}],
     zipcode => [str => {forbidden=>1}] ],
   [ province => ['str*', {not => 'Outside US'}],
     zipcode => [str => {required=>1}] ]
 ]}]

The above says: if province is set to 'Outside US', then zipcode must not be
specified. Otherwise if province is set to US states, zipcode is required.

 [array => {elem_deps => [
     [ '^0$',   ['str*'  => {one_of => ['int', 'integer']}],
       '[1-9]', ['hash*' => {keys_in => [qw/is not min max/]}] ],
     [ '^0$',   ['str*'  => {one_of => ['str', 'string']}],
       '[1-9]', ['hash*' => {keys_in => [qw/is not min max min_len max_len/]}]],
     [ '^0$',   ['str*'  => {one_of => ['bool', 'boolean']}],
       '[1-9]', ['hash*' => {keys_in => [qw/is not/]}] ],
 ]}]

The above says: if first element of array is a text with value 'int'/'integer',
then the following elements must be hash with specified keys. A similar rule is
there for first element being 'str'/'string' and 'bool'/'boolean'.

Example valid array:

 ['str', {min_len=>0, max_len=>1}, {is=>'a', isnt=>'b'}]

Example invalid array (key 'min_len' is not allowed):

 ['int', {min_len=>0, max_len=>1}, {is=>'a', isnt=>'b'}]

Note: You need to be careful with undef, because it matches all schema unless
required=>1 (or the shortcut 'foo*') is specified.

=cut

clause 'elem_deps',
    arg => '([regex, schema*, regex, schema*][])*',
    code => sub {
        my ($self, %args) = @_;
        $self->superclause_has_elems(%args, -which => 'elem_deps');
    };

1;
