package Sah::Type::Str;
# ABSTRACT: Specification for 'str' type

use Any::Moose '::Role';
use Sah::Util 'clause';
with
    'Sah::Type::Base',
    'Sah::Type::Comparable',
    'Sah::Type::Sortable',
    'Sah::Type::HasElement';

our $type_names = ['str', 'string'];

=head1 DESCRIPTION

Names: B<str>, B<string>

=head1 CLAUSES

'str' assumes the following roles: L<Sah::Type::Base>, L<Sah::Type::Comparable>,
L<Sah::Type::Sortable>, and L<Sah::Type::HasElement>. Consult the documentation
of those role(s) to see what clauses are available.

In addition, 'str' defines these clauses:

=head2 match_all => REGEX|[REGEX, ...]|{EMITTER=>(REGEX|[REGEX...])}

Aliases: B<matches_all>, B<match>, B<matches>, B<regex>, B<regexp>, B<pattern>,
B<patterns>.

Require that the string match all the specified regular expression(s).

Example:

 [str => {match => qr/^\w+$/}]

Since regular expressions might not be 100% compatible from language to language
due to different flavors/implementations, instead of avoiding the use of regex
entirely, you can specify different regex for each target language (emitter),
e.g.:

 [str => {match => {
   PHP    => '...',
   Perl   => qr/.../,
   Python => '...',
 }}]

=cut

my $t_re_or_res = 'regex*|regex*[]*|{str=>(regex*|regex*[]*)}';

clause 'match_all',
    aliases => ['matches_all', 'match', 'matches', 'regex', 'regexp',
                'pattern', 'patterns'],
    arg     => $t_re_or_res;

=head2 match_one => REGEX|[REGEX, ...]|{EMITTER=>(REGEX|[REGEX...]), ...}

Aliases: B<matches_one>

Require that the string match at least one the specified regular expression(s).

=cut

clause 'match_one',
    aliases => ['matches_one'],
    arg     => $t_re_or_res;

=head2 not_match => REGEX|[REGEX, ...]|{EMITTER=>(REGEX|[REGEX...]), ...}

Aliases: B<not_matches>

The opposite of B<match_all>, require that the string not match any of the
specified regular expression(s).

=cut

clause 'not_match',
    aliases => ['not_matches'],
    arg     => $t_re_or_res;

=head2 isa_regex => BOOL

If value is true, require that the string be a valid regular expression string.
If value is false, require that the string not be a valid regular expression
string.

=cut

clause 'isa_regex', arg => 'bool';

no Any::Moose;
1;
