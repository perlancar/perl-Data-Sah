package Data::Sah::Type::buf;

use Moo::Role;
with 'Data::Sah::Type::str';

# VERSION

1;
# ABSTRACT: Specification for type 'buf'

=head1 DESCRIPTION

'buf' stores binary data. Elements of buf data are bytes.


=head1 CLAUSES

buf derives from L<Data::Sah::Type::str>. Consult the documentation of those
role(s) to see what clauses are available.

Currently buf does not define additional clauses.

=cut
