package Data::Sah::Type::BaseType;
# why name it BaseType instead of Base? because I'm sick of having 5 files named
# Base.pm in my editor (there would be Type::Base and the various
# Compiler::*::Type::Base).

use Moo::Role;
use Data::Sah::Util 'has_clause';

has_clause 'default', prio => 1, arg => 'any';
has_clause 'SANITY', arg => 'any';
has_clause 'PREPROCESS', arg => 'any', prio => 5;
has_clause 'req', prio => 3, arg => 'bool';
has_clause 'forbidden', prio => 3, arg => 'bool';
has_clause 'name', arg => [array => {req=>1, of => 'str*'}];
has_clause 'summary', arg => [array => {req=>1, of => 'str*'}];
has_clause 'description', arg => [array => {req=>1, of => 'str*'}];
#has_clause 'deps', arg => [array => {req=>1, of => '[schema*, schema*]'}];
#has_clause 'prefilters', prio => 10, arg => '((expr*)[])*';
#has_clause 'postfilters', prio => 90, arg => '((expr*)[])*';
#has_clause 'lang', prio => 2, arg => 'str*';
#has_clause 'check', arg => 'expr*';

1;
# ABSTRACT: Specification for base type

=head1 DESCRIPTION

This is the specification for the 'BaseType' role. All Sah types directly or
indirectly consume this role.


=head1 CLAUSES

=head2 default

Supply a default value.

Priority: 1 (very high). This is processed before all other clauses.

Example: Given schema [int => {req=>1}] an undef data is invalid, but given
schema [int => {req=>1, default=>3}] an undef data is valid because it will be
given default value first.

=head2 SANITY

This is a "hidden" clause that cannot be specified in schemas (due to uppercase
spelling), but compilers use them to add checks.

Priority: 50 (default). Due to its spelling, by sorting, it will be processed
before all other normal clauses.

=head2 PREPROCESS

This is a "hidden" clause that cannot be specified in schemas (due to uppercase
spelling), but compilers use them to preprocess data before further checking
(for example, Perl compiler for the C<datetime> type can convert string data to
L<DateTime> object).

Priority: 5 (very high), executed after B<default> and B<req>/B<forbidden>.

=head2 req

If set to 1, require that data be defined. Otherwise, allow data to be undef
(the default behaviour).

Priority: 3 (very high), executed after B<default>.

By default, undef will pass even elaborate schema, e.g. [int => {min=>0,
max=>10, div_by=>3}] will still pass an undef. However, undef will not pass
[int=>{req=>1}].

This behaviour is much like NULLs in SQL: we *can't* (in)validate something that
is unknown/unset.

See also: B<forbidden>

=head2 forbidden

This is the opposite of B<req>, requiring that data be not defined (i.e. undef).

Priority: 3 (very high), executed after B<default>.

Given schema [int=>{forbidden=>1}], a non-undef value will fail. Another
example: the schema [int=>{req=>1, forbidden=>1}] will always fail due to
conflicting clauses.

See also: B<req>

=head2 prefilters => [EXPR, ...]

NOT YET IMPLEMENTED.

Run expression(s), usually to preprocess data before further checking. Data is
referred in expression by variable C<$.> (XXX or C<$data:.>? not yet fixed).

Priority: 10 (high). Run after B<default> and B<req>/B<forbidden> (and
B<PREPROCESS>).

=head2 postfilters => [EXPR, ...]

NOT YET IMPLEMENTED.

Run expression(s), usually to postprocess data.

Priority: 90 (very low). Run after all other clauses.

=head2 lang => LANG

NOT YET IMPLEMENTED.

Set language for this schema.

Priority: 2 (very high)

=head2 name => STR

A short short (usually single-word, without any formatting) to name the schema,
useful for identifying the schema when used as a type for human compiler.

To store translations, you can use clause attributes.

Example:

 [str => {
     'name:en' => 'regex',
     'name:id' => 'regex',
     isa_regex => 1,
 }]

Priority: 50 (default).

See also: B<summary>, B<description>.

=head2 summary => STR

A one-line text (about 70-80 character max, without any formatting) to describe
the schema. This is useful, e.g. for manually describe a schema instead of using
the human compiler. It can also be used in form field labels.

To store translations, you can use clause attributes.

Example:

 # definition for 'single_dice_throw' schema/type
 [int => {
     req => 1,
     'summary:en' => 'A number representing result of single dice throw (1-6)',
     'summary:id' => 'Bilangan yang menyatakan hasil lempar sebuah dadu (1-6)',
     between => [1, 6],
 }]

Using the human compiler, the above schema will be output as the standard, more
boring 'Integer, value between 1 and 6.'

Priority: 50 (default).

See also: B<name>, B<description>.

=head2 description => STR

A longer text (a paragraph or more) to describe the schema, useful e.g. for
help/usage text. Text should be in Org format.

To store translations, you can use clause attributes.

Example:

 {
     name => 'http_headers',
     description => <<EOT,
 HTTP headers should be specified as an array of 2-element arrays (pairs). Each
 pair should contain header name in the first element (all lowercase, *-*
 written as *_*) and header value in the second element.

 Example:

 : [[content_type => 'text/html'], [accept => 'text/html'], [accept => '*/*']]

 EOT
     type => 'array',
     clause_sets => {
         req => 1,
         of => 'http_header',
     },
     def => {
         http_header => [array => {req=>1, len => 2}],
     },
 }

Priority: 50 (default).

See also: B<name>, B<summary>.

=head2 deps => [[SCHEMA1, SCHEMA2], [SCHEMA1B, SCHEMA2B], ...]

NOT YET IMPLEMENTED.

If data matches SCHEMA1, then data must also match SCHEMA2, and so on. This is
not unlike an if-elsif statement. The clause will fail if any of the condition
is not met.

Priority: 50 (normal).

Example:

 [either => {
   set => 1,
   of => [qw/str array hash/],
   deps => [
     [str   => [str   => {min_len => 1}]],
     [array => [array => {min_len => 1, of => "str"}]],
     [hash  => [hash  => {values_of => "str"}]],
   ]}
 ]

The above schema states: data can be a string, array, or hash. If it is a
string, it must have a nonzero length. If it is an array, it must be a
nonzero-length array of strings. If it is a hash then all values must be
strings.

=head2 check => EXPR

NOT YET IMPLEMENTED.

Evaluate expression, which must evaluate to a true value for this clause to
succeed.

Priority: 50 (normal).

=cut
