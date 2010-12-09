package Sah::Type::CIStr;
# ABSTRACT: Specification for 'cistr' (case-insensitive string) type

=head1 DESCRIPTION

Names: B<cistring>, B<cistr>

This is specification for 'cistr'. 'cistr' is just like 'str' except that
comparison/sorting/regex matching is done case-insensitively.

=cut

use Any::Moose '::Role';
with
    'Sah::Type::Str';

our $type_names = ["cistr", "cistring"];

=head1 SEE ALSO

L<Sah::Type::Str>

=cut

no Any::Moose;
1;
