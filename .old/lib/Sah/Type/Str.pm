package Data::Schema::Spec::v10::Type::Str;
# ABSTRACT: Specification for 'str' type

use Any::Moose '::Role';
use Data::Schema::Util 'attr', 'attr_conflict';
with
    'Data::Schema::Spec::v10::Type::Base',
    'Data::Schema::Spec::v10::Type::Comparable',
    'Data::Schema::Spec::v10::Type::Sortable',
    'Data::Schema::Spec::v10::Type::HasElement';

our $typenames = ['str', 'string'];

=head1 TYPE ATTRIBUTES

'Str' assumes the following roles: L<Data::Schema::Spec::v10::Type::Base>,
L<Data::Schema::Spec::v10::Type::Comparable>,
L<Data::Schema::Spec::v10::Type::Sortable>, and
L<Data::Schema::Spec::v10::Type::HasElement>. Consult the documentation of those
role(s) to see what type attributes are available.

In addition, 'str' defines these attributes:

=head2 match_all => REGEX|[REGEX, ...]|{EMITTER=>(REGEX|[REGEX...])}

Aliases: B<matches_all>, B<match>, B<matches>

Require that the string match all the specified regular expression(s).

Example:

 [str => {match => qr/^\w+$/}]

Since regular expressions might not be 100% compatible from language to language
due to different flavors/implementations, instead of avoiding the use of regex
entirely, you can specify different regex for each target language (emitter),
e.g.:

 [str => {match => {
   php => '...',
   perl => qr/.../,
   python => '...',
 }}]

=cut

attr 'match_all',
    aliases => ['matches_all', 'match', 'matches'],
    arg => 'regex*|regex*[]*|{str=>(regex*|regex*[]*)}';

=head2 match_one => REGEX|[REGEX, ...]|{EMITTER=>(REGEX|[REGEX...]), ...}

Aliases: B<matches_one>

Require that the string match at least one the specified regular expression(s).

=cut

attr 'match_one',
    aliases => ['matches_one'],
    arg => 'regex*|regex*[]*|{str=>(regex*|regex*[]*)}';

=head2 not_match => REGEX|[REGEX, ...]|{EMITTER=>(REGEX|[REGEX...]), ...}

Aliases: B<not_matches>

The opposite of B<match_all>, require that the string not match any of the
specified regular expression(s).

=cut

attr 'not_match',
    aliases => ['not_matches'],
    arg => 'regex*|regex*[]*|{str=>(regex*|regex*[]*)}';

=head2 isa_regex => BOOL

If value is true, require that the string be a valid regular expression string.
If value is false, require that the string not be a valid regular expression
string.

Example:

 ds_validate("(foo|bar)" => [str => {set=>1, isa_regex=>1}); # valid
 ds_validate("(foo|bar"  => [str => {set=>1, isa_regex=>1}); # invalid, unmatched "(" in regex
 ds_validate("(foo|bar"  => [str => {set=>1, isa_regex=>0}); # valid

=cut

attr 'isa_regex', arg => 'bool';

no Any::Moose;
1;
