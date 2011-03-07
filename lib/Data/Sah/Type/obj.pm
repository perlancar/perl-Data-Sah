package Data::Sah::Type::obj;
# ABSTRACT: Specification for obj type

=head1 DESCRIPTION

You can validate objects with this type.

Example schema:

 [obj => {can => ['compile']}];

Example valid data:

 Sah->new(); # can compile()

Example invalid data:

 IO::Handler->new(); # cannot compile()
 1;                  # in 'normal' Perl, not an object

=cut

use Moo::Role;
use Data::Sah::Util 'clause';
with 'Data::Sah::Type::BaseType';

=head1 CLAUSES

'obj' assumes the following roles: L<Data::Sah::Type::Base>. Consult the documentation
of those role(s) to see what type clauses are available.

In addition, obj defines these clauses:

=head2 can => METHOD

Requires that the object support the specified method.

=cut

clause 'can', arg => 'str*';

=head2 cant => METHOD

Requires that the object not support the specified method.

=cut

clause 'cant', arg => 'str*';

=head2 can_one => [METHOD, ...]

Requires that the object be able to do any one of the specified methods.

=cut

clause 'can_one', arg => 'str*[]*';

=head2 can_all =>  [METHOD, ...]

Requires that the object be able to do all of the specified methods.

=cut

clause 'can_all', arg => 'str*[]*';

=head2 can_none  => [METHOD, ...]

Requires that the object not be able to do any of the specified methods.

=cut

clause 'can_none', arg => 'str*[]*';

=head2 isa => CLASS

Requires that the object be of any one of the specified classes.

=cut

clause 'isa_one', arg => 'str*';

=head2 not_isa => CLASS

Requires that the object not be of any one of the specified classes.

=cut

clause 'not_isa', arg => 'str*';

=head2 isa_all => [CLASS, ...]

Requires that the object be of all of the specified classes.

=cut

clause 'isa_all', arg => 'str*[]*';

=head2 isa_any => [CLASS, ...]

Requires that the object be of any of the specified classes.

=cut

clause 'isa_any', arg => 'str*[]*';

=head2 isa_none => [CLASS, ...]

Requires that the object not be of any of the specified classes.

=cut

clause 'isa_none', arg => 'str*[]*';

1;
