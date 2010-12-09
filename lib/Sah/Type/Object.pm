package Sah::Type::Object;
# ABSTRACT: Specification for 'object' type

=head1 DESCRIPTION

Names: B<object>, B<obj>

You can validate objects with this type.

Example schema:

 [object => {can => ['compile']}];

Example valid data:

 Sah->new(); # can compile()

Example invalid data:

 IO::Handler->new(); # cannot compile()
 1;                  # in 'normal' Perl, not an object

=cut

use Any::Moose '::Role';
use Sah::Util 'clause';
with
    'Sah::Type::Base';

our $type_names = ["obj", "object"];

=head1 CLAUSES

'Object' assumes the following role: L<Sah::Type::Base>. Consult the
documentation of those role(s) to see what type clauses are available.

In addition, object defines these clauses:

=head2 can_one => (meth OR [meth, ...])

Requires that the object be able to do any one of the specified methods.

=cut

clause 'can_one', arg => 'str*|(str*)[]*';

=head2 can_all => (meth OR [meth, ...])

Aliases: B<can>

Requires that the object be able to do all of the specified methods.

=cut

clause 'can_all', alias => 'can', arg => 'str*|(str*)[]*';

=head2 cannot  => (meth OR [meth, ...])

Aliases: B<cant>

Requires that the object not be able to do any of the specified methods.

=cut

clause 'cannot', alias => 'cant', arg => 'str*|(str*)[]*';

=head2 isa_one => (class OR [class, ...])

Requires that the object be of any one of the specified classes.

=cut

clause 'isa_one', arg => 'str*|(str*)[]*';

=head2 isa_all => (class OR [class, ...])

Aliases: B<isa>

Requires that the object be of all of the specified classes.

=cut

clause 'isa_all', alias => 'isa', arg => 'str*|(str*)[]*';

=head2 not_isa => (class OR [class, ...])

Requires that the object not be of any of the specified classes.

=cut

clause 'not_isa', arg => 'str*|(str*)[]*';

no Any::Moose;
1;
