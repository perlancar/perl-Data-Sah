package Data::Sah::Type::str;

use Moo::Role;
use Data::Sah::Util 'has_clause';
with 'Data::Sah::Type::BaseType';
with 'Data::Sah::Type::Comparable';
with 'Data::Sah::Type::Sortable';
with 'Data::Sah::Type::HasElems';

my $t_re = 'regex*|{*=>regex*}';
my $t_res = [array=>{of=>$t_re, required=>1}];

has_clause 'not_match', arg => $t_re;
has_clause 'match_any', arg => $t_res;
has_clause 'is_regex', arg => 'bool';
has_clause 'match_none', arg => $t_res;
has_clause 'match_all', arg => $t_res;
has_clause 'match', arg => $t_re;

1;
# Specification for type 'str'

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

See also: B<match_all>, B<match_any> for matching against multiple regexes.

=head2 not_match => REGEX|{COMPILER=>REGEX, ...}

Require that string not match the specified regular expression.

=head2 match_all => [REGEX, ...]|{COMPILER=>[REGEX...], ...}

Require that the string match all the specified regular expressions.

See also: B<match_any>, B<match>.

=head2 match_any => [REGEX, ...]|{COMPILER=>[REGEX...], ...}

Require that the string match any the specified regular expressions.

See also: B<match_any>, B<match_none>.

=head2 match_none => [REGEX, ...]|{COMPILER=>[REGEX...], ...}

The opposite of B<match_all>, require that the string not match any of the
specified regular expression(s).

See also: B<match_all>, B<match_any>.

=head2 is_regex => BOOL

If value is true, require that the string be a valid regular expression string.
If value is false, require that the string not be a valid regular expression
string.

=cut

