package Data::Schema::Spec::v10::Type::CIStr;
# ABSTRACT: Specification for 'cistr' (case-insensitive string) type

=head1 DESCRIPTION

This is specification for 'cistr'. 'cistr' is just like 'str' except that
comparison/sorting/regex matching is done case-insensitively.

=cut

use Any::Moose '::Role';
with
    'Data::Schema::Spec::v10::Type::Str';

our $typenames = ["cistr", "cistring"];

=head1 SEE ALSO

L<Data::Schema::Spec::v10::Type::Str>

=cut

no Any::Moose;
1;
