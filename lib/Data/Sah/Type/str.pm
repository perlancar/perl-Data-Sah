package Data::Sah::Type::str;

use Moo::Role;
use Data::Sah::Util 'has_clause';
with 'Data::Sah::Type::BaseType';
with 'Data::Sah::Type::Comparable';
with 'Data::Sah::Type::Sortable';
with 'Data::Sah::Type::HasElems';

my $t_re = 'regex*|{*=>regex*}';

has_clause 'match', arg => $t_re;
has_clause 'is_regex', arg => 'bool';

1;
# ABSTRACT: Specification for type 'str'

=head1 DESCRIPTION

str stores text. Elements of str are characters. The default encoding is utf8.


=head1 CLAUSES

Unless specified otherwise, all clauses have a priority of 50 (normal).

str assumes the following roles: L<Data::Sah::Type::Base>,
L<Data::Sah::Type::Comparable>, L<Data::Sah::Type::Sortable>, and
L<Data::Sah::Type::HasElems>. Consult the documentation of those role(s) to see
what clauses are available.

In addition, str defines these clauses:

=head2 match => REGEX|{COMPILER=>REGEX, ...}

Require that string match the specified regular expression.

Since regular expressions might not be 100% compatible from language to language
due to different flavors/implementations, instead of avoiding the use of regex
entirely, you can specify different regex for each target language, e.g.:

 [str => {match => {
   js     => '...',
   perl   => '...',
   python => '...',
 }}]

Note that to match multiple regexes or revert, you can utilize the clause
attributes 'values' and 'revert':

 # string must match a, b, and c
 [str => {"match.values"=>[a, b, c]}]

 # idem, shortcut form
 [str => {"match&"=>[a, b, c]}]

 # string must match either a or b or c
 [str => {"match.values"=>[a, b, c], "match.min_ok"=>1}]

 # idem, shortcut form
 [str => {"match|"=>[a, b, c]}]

 # string must NOT match a
 [str => {match=>a, "match.max_ok"=>0}]

 # idem, shortcut form
 [str => {"!match"=>a}]

 # string must NOT match a nor b nor c (i.e. must match none of those)
 [str => {"match.values"=>[a, b, c], "match.max_ok"=>0}]

 # string must at least not match a or b or c (i.e. if all match, schema fail;
 # if at least one does not match, schema succeeds)
 [str => {"match.values"=>[a, b, c], "match.min_nok"=>1}]

=head2 is_regex => BOOL

If value is true, require that the string be a valid regular expression string.
If value is false, require that the string not be a valid regular expression
string.

=cut

