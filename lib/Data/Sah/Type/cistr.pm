package Data::Sah::Type::cistr;
# ABSTRACT: Specification for 'cistr' (case-insensitive string) type

=head1 DESCRIPTION

This is specification for 'cistr'. 'cistr' is just like 'str' except that
comparison/sorting/regex matching is done case-insensitively.

=cut

use Any::Moose '::Role';
with
    'Sah::Type::str';

=head1 SEE ALSO

L<Data::Sah::Type::str>

=cut

no Any::Moose;
1;
