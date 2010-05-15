package Data::Schema::Type::Str;
# ABSTRACT: Specification for 'str' type

use Any::Moose '::Role';
use Data::Schema::Util 'attr', 'attr_conflict';
with
    'Data::Schema::Type::Base',
    'Data::Schema::Type::Comparable',
    'Data::Schema::Type::Sortable',
    'Data::Schema::Type::HasElement';

our $typenames = ['str', 'string'];

=head1 TYPE ATTRIBUTES

'Str' assumes the following roles: L<Data::Schema::Type::Base>,
L<Data::Schema::Type::Comparable>, L<Data::Schema::Type::Sortable>,
and L<Data::Schema::Type::HasElement>. Consult the documentation of
those role(s) to see what type attributes are available.

In addition, 'str' defines these attributes:

=head2 match => REGEX

Aliases: B<matches>

Require that the string match a regular expression.

=cut

attr 'match', aliases => 'matches', arg => 'regex*';

=head2 not_match => REGEX

Aliases: B<not_matches>

The opposite of B<match>, require that the string not match a regular
expression.

=cut

attr 'not_match', aliases => 'not_matches', arg => 'regex*';

=head2 isa_regex => BOOL

If value is true, require that the string be a valid regular
expression string. If value is false, require that the string not be a
valid regular expression string.

Example:

 ds_validate("(foo|bar)" => [str => {set=>1, isa_regex=>1}); # valid
 ds_validate("(foo|bar"  => [str => {set=>1, isa_regex=>1}); # invalid, unmatched "(" in regex
 ds_validate("(foo|bar"  => [str => {set=>1, isa_regex=>0}); # valid

=cut

attr 'isa_regex', arg => 'bool';

no Any::Moose;
1;
