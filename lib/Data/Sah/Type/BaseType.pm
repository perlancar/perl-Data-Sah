package Data::Sah::Type::BaseType;
# why name it BaseType instead of Base? because I'm sick of having 5 files named
# Base.pm in my editor (there would be Type::Base and the various
# Compiler::*::Type::Base).

use Moo::Role;
#use Data::Sah::Schemas::Common;
#use Data::Sah::Schemas::Schema;
use Data::Sah::Util 'has_clause';

has_clause 'default', prio => 1, arg => 'any', tags=>[];

has_clause 'min_ok',  prio => 2, arg => 'pos_int*', tags=>['meta'];
has_clause 'min_nok', prio => 2, arg => 'pos_int*', tags=>['meta'];
has_clause 'max_ok',  prio => 2, arg => 'pos_int*', tags=>['meta'];
has_clause 'max_nok', prio => 2, arg => 'pos_int*', tags=>['meta'];

#has_clause 'lang',    prio => 2, arg => 'str*', tags=>['meta'];

has_clause 'req',         prio => 3, arg => 'bool', tags=>['constraint'];
has_clause 'forbidden',   prio => 3, arg => 'bool', tags=>['constraint'];

has_clause 'PREPROCESS',  prio => 5, arg => 'any';
has_clause 'POSTPROCESS', prio => 5, arg => 'any';

has_clause 'SANITY',      arg => 'any', tags=>['constraint'];

has_clause 'name',        arg => 'str*', tags=>['meta'];
has_clause 'summary',     arg => 'str*', tags=>['meta'];
has_clause 'description', arg => 'str*', tags=>['meta'];
has_clause 'comment',     arg => 'str*', tags=>['meta'];
has_clause 'tags',        arg => ['array*', of=>'str*'], tags=>['meta'];

has_clause 'noop', arg => 'any',  tags=>['constraint'];
has_clause 'fail', arg => 'bool', tags=>['constraint'];

#has_clause 'if', ..., tags=>['constraint']
#has_clause 'prefilters', prio => 10, arg => '((expr*)[])*', tags=>[''];
#has_clause 'postfilters', prio => 90, arg => '((expr*)[])*', tags=>[''];
#has_clause 'check', arg => 'expr*', tags=>['constraint'];

1;
# ABSTRACT: Specification for base type

=head1 DESCRIPTION

This is the specification for the 'BaseType' role. All Sah types directly or
indirectly consume this role.

Unless mentioned explicitly, priority is 50 (default).


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

Priority: 50 (default), but due to its spelling, by sorting, it will be
processed before all other normal clauses.

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
referred to in expression by variable C<$_>. Prefiltered value will persist
until the end of all other clauses, and after that will be restored by the
B<POSTPROCESS> clause.

Priority: 10 (high). Run after B<default> and B<req>/B<forbidden> (and
B<PREPROCESS>).

Specific attributes: B<permanent>. If set to true, then prefiltered value will
persist and won't be restored by B<POSTPROCESS>.

=head2 postfilters => [EXPR, ...]

NOT YET IMPLEMENTED.

Run expression(s), usually to postprocess data. Data is referred to in
expression by variable C<$_>. From here on, the data will be permanently set to
the postfiltered value.

Priority: 90 (very low). Run after all other clauses, before B<POSTPROCESS>.

=head2 POSTPROCESS

This is a "hidden" clause that cannot be specified in schemas (due to uppercase
spelling), compilers use them to restore value temporarily changed by prefilters
(unless the prefilter is set to be permanent, or between schemas in B<deps>, see
the B<deps> clause).

Priority: 95 (very low). Run after all the other clauses.

=head2 lang => LOCALECODE

NOT YET IMPLEMENTED.

Set language for this schema.

Priority: 2 (very high)

=head2 name => STR

A short short (usually single-word, without any formatting) to name the schema,
useful for identifying the schema when used as a type for human compiler.

To store translations, you can use the B<alt.lang.*> clause attributes.

Example:

 [int => {
     'name:alt.lang.en_US' => 'pos_int',
     'name:alt.lang.id_ID' => 'bil_pos',
     min=>0,
 }]

See also: B<summary>, B<description>, B<comment>, B<tags>.

=head2 summary => STR

A one-line text (about 70-80 character max, without any formatting) to describe
the schema. This is useful, e.g. for manually describe a schema instead of using
the human compiler. It can also be used in form field labels.

To store translations, you can use the B<alt.lang.*> clause attributes.

Example:

 # definition for 'single_dice_throw' schema/type
 [int => {
     req => 1,
     'summary:alt.lang.en_US' =>
         'A number representing result of single dice throw (1-6)',
     'summary:alt.lang.id_ID' =>
         'Bilangan yang menyatakan hasil lempar sebuah dadu (1-6)',
     between => [1, 6],
 }]

Using the human compiler, the above schema will be output as the standard, more
boring 'Integer, value between 1 and 6.'

See also: B<name>, B<description>, B<comment>, B<tags>.

=head2 description => STR

A longer text (a paragraph or more) to describe the schema, useful e.g. for
help/usage text. Text should be in Org format.

To store translations, you can use the B<alt.lang.*> clause attributes.

Example:

 [array => {
     name        => 'http_headers',
     description => <<EOT,
 HTTP headers should be specified as an array of 2-element arrays (pairs). Each
 pair should contain header name in the first element (all lowercase, *-*
 written as *_*) and header value in the second element.

 Example:

 : [[content_type => 'text/html'], [accept => 'text/html'], [accept => '*/*']]

 EOT
     req => 1,
     of  => 'http_header',
  },
  {
      def => {
          http_header => ['array*', len=>2],
      },
 }]

See also: B<name>, B<summary>, B<comment>, B<tags>.

=head2 comment => STR

Can contain any kind of text (format unspecified), will be ignored during
validation. Meant to store internal comment (for schema authors/developers).

See also: B<name>, B<summary>, B<description>, B<tags>.

=head2 tags => ARRAY OF STR

A list of tags, can be used to categorize schemas.

See also: B<name>, B<summary>, B<description>, B<comment>.

=head2 noop => ANY

Will do nothing. This clause is just a convenience if you want to do nothing (or
perhaps just use the attributes of this clause to do things).

=head2 fail => BOOL

If set to 1, validation of this clause always fails. This is just a convenience
to force failure.

=head2 if => [CLAUSE1=>VAL, CLAUSE2=>VAL] or [CLAUSE_SET(S)1, CLAUSE_SET(S)2]

NOT YET IMPLEMENTED.

This is similar to deps, but instead of using schemas as arguments, clauses are
used. The first form (4-argument) states that if CLAUSE1 succeeds, then CLAUSE2
must also succeed. The second form (2-argument) operates on a clause set (hash)
or clause sets (array of hashes).

Examples:

 # leap year
 [int => {div_by=>4, if => [div_by => 100, div_by => 400]]

The "if" clause states that if input number is divisible by 100, it must
also divisible by 400. Otherwise, the clause fails.

 [str => {min_len=>1, max_len=>10,
          if => [ {min_len=>4, max_len=>6}, {is_palindrome=>1} ]}]

The above says that if a string has length between 4 and 6 then it must be a
palindrome. Otherwise it doesn't have to be one. But nevertheless, all input
must be between 1 and 10 characters long.

 [str => {if => [ [{match=>'a'}, {match=>'b'}],
                  [{match=>'c'}, {match=>'d'}] ]}]

The above says that if a string matches 'a' and 'b', it must also match 'c' and
'd'. As a side note, the above schema can also be written as:

 [str => {if => [ 'match&'=>['a', 'b'], 'match&'=>['c', 'd'] ]}]

=head2 check => EXPR

NOT YET IMPLEMENTED.

Evaluate expression, which must evaluate to a true value for this clause to
succeed.

=head2 min_ok => N

This clause specifies the required minimum number of check clauses that must
succeed in order for the whole clause set to be considered a success. By default
this is not defined. You can use this clause to only require certain number of
(instead of all) checks.

Note that the {min,max}_{ok,nok} themselves are not counted into number of
successes/failures, as they are not considered as constraint clauses.

Priority: 2 (very high, evaluated after B<default> clause).

Example:

 [str => {min_ok=>1, min_len=>8, match=>qr/\W/}]

The above schema requires a string to be at least 8 characters long, B<or>
contains a non-word character. Strings that would validate include: C<abcdefgh>
or C<$> or C<$abcdefg>. Strings that would not validate include: C<abcd> (fails
both C<min_len> and C<match> clauses).

See also: B<max_ok>, B<min_nok>, B<max_nok>.

=head2 max_ok => N

This clause specifies the maximum number of check clauses that succeed in order
for the whole clause set to be considered a success. By default this is not
defined. You can use this clause to require a number of failures in the checks.

Note that the {min,max}_{ok,nok} themselves are not counted into number of
successes/failures, as they are not considered as constraint clauses.

Priority: 2 (very high, evaluated after B<default> clause).

Example:

 [str => {min_ok=>1, max_ok=>1, min_len=>8, match=>qr/\W/}]

The above schema states that string must either be longer than 8 characters or
contains a non-word character, I<but not both>. Strings that would validate
include: C<abcdefgh> or C<$>. Strings that would not validate include:
C<$abcdefg> (match both clauses, so max_ok is not satisfied).

See also: B<max_ok>, B<min_nok>, B<max_nok>.

=head2 min_nok => N

This clause specifies the required minimum number of check clauses that must
fail in order for the whole clause set to be considered a success. By default
this is not defined. You can use this clause to require a certain number of
failures.

Note that the {min,max}_{ok,nok} themselves are not counted into number of
successes/failures, as they are not considered as constraint clauses.

Priority: 2 (very high, evaluated after B<default> clause).

Example:

 [str => {min_nok=>1, min_len=>8, match=>qr/\W/}]

The above schema requires a string to be shorter than 8 characters or devoid of
non-word characters. Strings that would validate include: C<abcdefghi> (fails
the C<match> clause), C<$abcd> (fails C<min_len> clause), or C<a> (fails both
clauses). Strings that would not validate include: C<$abcdefg>.

See also: B<max_ok>, B<min_nok>, B<max_nok>.

=head2 max_nok => N

This clause specifies the maximum number of check failures that succeed in order
for the whole clause set to be considered a success. By default this is not
defined (but when none of the {min,max}_{ok,nok} is defined, the default
behavior is to require all clauses to succeed, in other words, as if C<max_nok>
were 0). You can use this clause to allow a certain number of failures in the
checks.

Note that the {min,max}_{ok,nok} themselves are not counted into number of
successes/failures, as they are not considered as constraint clauses.

Priority: 2 (very high, evaluated after B<default> clause).

Example:

 [str => {max_nok=>1, min_len=>8, match=>qr/\W/}]

The above schema states that string must either be longer than 8 characters or
contains two non-word characters, I<or both>. Strings that would validate
include: C<abcdefgh>, C<$$>, C<$abcdefgh>. Strings that would not validate
include: C<abcd> (fails both C<min_len> and C<match> clauses).

See also: B<max_ok>, B<min_nok>, B<max_nok>.

=cut
