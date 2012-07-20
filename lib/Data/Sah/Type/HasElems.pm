package Data::Sah::Type::HasElems;

use Moo::Role;
use Data::Sah::Util 'has_clause';

requires 'superclause_has_elems';

has_clause 'max_len',
    arg     => ['int*' => {min=>0}],
    code    => sub {
        my ($self, $cd) = @_;
        $self->superclause_has_elems('max_len', $cd);
    };

has_clause 'min_len',
    arg     => ['int*' => {min=>0}],
    code    => sub {
        my ($self, $cd) = @_;
        $self->superclause_has_elems('min_len', $cd);
    };

has_clause 'len_between',
    arg   => ['array*' => {elements => ['int*', 'int*']}],
    code  => sub {
        my ($self, $cd) = @_;
        $self->superclause_has_elems('len_between', $cd);
    };

has_clause 'len',
    arg   => ['int*' => {min=>0}],
    code  => sub {
        my ($self, $cd) = @_;
        $self->superclause_has_elems('len', $cd);
    };

has_clause 'has',
    arg => 'any',
    code => sub {
        my ($self, $cd) = @_;
        $self->superclause_has_elems('has', $cd);
    };

has_clause 'all_elems',
    arg => 'schema*',
    code => sub {
        my ($self, $cd) = @_;
        $self->superclause_has_elems('all_elems', $cd);
    };

has_clause 'elem_deps',
    arg => '([regex, schema*, regex, schema*][])*',
    code => sub {
        my ($self, $cd) = @_;
        $self->superclause_has_elems('elem_deps', $cd);
    };

1;
# ABSTRACT: Specification for types that have the notion of elements

=head1 DESCRIPTION

This is the role for types that have the notion of elements/length. It provides
clauses like B<max_len>, B<len>, B<len_between>, B<all_elems>, etc. It is used
by 'array', 'hash', and also 'str'.

Role consumer must provide method 'superclause_has_elems' which will receive the
same %args as clause methods, but with additional key: -which (either 'max_len',
'min_len', 'len', 'len_between', 'has_any', 'has_all', 'has_none', 'has',
'hasnt').


=head1 CLAUSES

=head2 max_len => LEN

Requires that the data have at most LEN elements.

Example:

 [str, {req=>1, max_len=>10}] # define a string with at most 10 characters

=head2 min_len => LEN

Requires that the data have at least LEN elements.

Example:

 [array, {min_len=>1}] # define an array with at least one element

=head2 len_between => [MIN, MAX]

A convenience clause that combines B<min_len> and B<max_len>.

Example, the two schemas below are equivalent:

 [str, {len_between=>[1, 10]}]
 [str, {min_len=>1, max_len=>10}]

=head2 len => LEN

Requires that the data have exactly LEN elements.

=head2 has => ELEM

Requires that the data contain the element.

Examples:

 # requires that array has element x
 [array => {has => x}]

 # requires that array has elements x, y, and z
 [array => {'has&' => [x, y, z]}]

 # requires that array does not have element x
 [array => {'!has' => x}]

=head2 all_elems => SCHEMA

Requires that every element of the data validate to the specified schema.

Note: filters applied by SCHEMA to elements will be preserved.

Examples:

 [array => {all_elems => 'int'}]

The above specifies an array of ints.

 [hash => {all_elems => [str => { match => '^[A-Za-z0-9]+$' }]}]

The above specifies hash with alphanumeric-only values.

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
     [ '^0$',   ['str*'  => {in => ['int', 'integer']}],
       '[1-9]', ['hash*' => {keys_in => [qw/is not min max/]}] ],
     [ '^0$',   ['str*'  => {in => ['str', 'string']}],
       '[1-9]', ['hash*' => {keys_in => [qw/is not min max min_len max_len/]}]],
     [ '^0$',   ['str*'  => {in => ['bool', 'boolean']}],
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
req=>1 (or the shortcut 'foo*') is specified.

=cut

