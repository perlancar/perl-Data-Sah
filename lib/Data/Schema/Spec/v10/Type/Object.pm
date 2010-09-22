package Data::Schema::Spec::v10::Type::Object;
# ABSTRACT: Specification for 'object' type

=head1 DESCRIPTION

Aliases: B<obj>

You can validate objects with this type.

Example schema:

 [object => {can => ['validate']}];

Example valid data:

 Data::Schema->new(); # can validate()

Example invalid data:

 IO::Handler->new(); # cannot validate()
 1;                  # in 'normal' Perl, not an object

=cut

use Any::Moose '::Role';
use Data::Schema::Util 'attr';
with
    'Data::Schema::Spec::v10::Type::Base';

our $typenames = ["obj", "object"];

=head1 TYPE ATTRIBUTES

'Object' assumes the following role: L<Data::Schema::Spec::v10::Type::Base>.
Consult the documentation of those role(s) to see what type attributes are
available.

In addition, object defines these attributes:

=head2 can_one => (meth OR [meth, ...])

Requires that the object be able to do any one of the specified methods.

=cut

attr 'can_one', arg => 'str*|(str*)[]*';

=head2 can_all => (meth OR [meth, ...])

Aliases: B<can>

Requires that the object be able to do all of the specified methods.

=cut

attr 'can_all', alias => 'can', arg => 'str*|(str*)[]*';

=head2 cannot  => (meth OR [meth, ...])

Aliases: B<cant>

Requires that the object not be able to do any of the specified methods.

=cut

attr 'cannot', alias => 'cant', arg => 'str*|(str*)[]*';

=head2 isa_one => (class OR [class, ...])

Requires that the object be of any one of the specified classes.

=cut

attr 'isa_one', arg => 'str*|(str*)[]*';

=head2 isa_all => (class OR [class, ...])

Aliases: B<isa>

Requires that the object be of all of the specified classes.

=cut

attr 'isa_all', alias => 'isa', arg => 'str*|(str*)[]*';

=head2 not_isa => (class OR [class, ...])

Requires that the object not be of any of the specified classes.

=cut

attr 'not_isa', arg => 'str*|(str*)[]*';

no Any::Moose;
1;
