package Data::Sah::Type::str;
# ABSTRACT: Specification for str type

use Any::Moose '::Role';
use Data::Sah::Util 'clause';
with
    'Data::Sah::Type::BaseType',
    'Data::Sah::Type::Comparable',
    'Data::Sah::Type::Sortable',
    'Data::Sah::Type::HasElems';

=head1 DESCRIPTION

This is the specification for the str type (strings).

=head1 CLAUSES

str assumes the following roles: L<Data::Sah::Type::Base>, L<Data::Sah::Type::Comparable>,
L<Data::Sah::Type::Sortable>, and L<Data::Sah::Type::HasElement>. Consult the documentation
of those role(s) to see what clauses are available.

In addition, str defines these clauses:

=head2 match => REGEX|{EMITTER=>REGEX, ...}

Require that string match the specified regular expression.

Since regular expressions might not be 100% compatible from language to language
due to different flavors/implementations, instead of avoiding the use of regex
entirely, you can specify different regex for each target language (emitter),
e.g.:

 [str => {match => {
   PHP    => '...',
   Perl   => qr/.../,
   Python => '...',
 }}]

See also: B<match_all>, B<match_any> for matching against multiple regexes.

=cut

my $t_re = 'regex*|{*=>regex*}';
my $t_res = [array=>{of=>$t_re, required=>1}];

clause 'match',
    arg     => $t_re;

=head2 not_match => REGEX|{EMITTER=>REGEX, ...}

Require that string not match the specified regular expression.

=cut

clause 'not_match',
    arg     => $t_re;

=head2 match_all => [REGEX, ...]|{EMITTER=>[REGEX...], ...}

Require that the string match all the specified regular expressions.

See also: B<match_any>, B<match>.

=cut

clause 'match_all',
    arg     => $t_res;

=head2 match_any => [REGEX, ...]|{EMITTER=>[REGEX...], ...}

Require that the string match any the specified regular expressions.

See also: B<match_any>, B<match_none>.

=cut

clause 'match_any',
    arg     => $t_res;

=head2 match_none => [REGEX, ...]|{EMITTER=>[REGEX...], ...}

The opposite of B<match_all>, require that the string not match any of the
specified regular expression(s).

See also: B<match_all>, B<match_any>.

=cut

clause 'match_none',
    arg     => $t_res;

=head2 isa_regex => BOOL

If value is true, require that the string be a valid regular expression string.
If value is false, require that the string not be a valid regular expression
string.

=cut

clause 'isa_regex', arg => 'bool';

no Any::Moose;
1;
