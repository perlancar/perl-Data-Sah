package Data::Schema::Type::CIStr;
# ABSTRACT: Specification for 'cistr' (case-insensitive string) type

=head1 DESCRIPTION

This is specification for 'cistr'. 'cistr' is just like 'str' except
that comparison/sorting/regex matching is done case-insensitively.

=cut

use Any::Moose '::Role';
with
    'Data::Schema::Type::Str';

our $typenames = ["cistr", "cistring"];

=head1 SEE ALSO

L<Data::Schema::Type::Str>

=cut

no Any::Moose;
1;
