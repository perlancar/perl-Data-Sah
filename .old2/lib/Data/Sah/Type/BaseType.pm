package Data::Sah::Type::BaseType;
# ABSTRACT: Specification for base type

=head1 DESCRIPTION

This is the specification for the base type. All types have the clauses
specified below.

=cut

use Moo::Role;
use Data::Sah::Util 'clause', 'clause_conflict';

# this must not be redefined by subrole or consumer class

=head1 METHODS

=cut

=head2 list_clauses() -> ARRAY

Return list of known type clause names.

=cut

sub list_clauses {
    my ($self) = @_;
    my @res;
    for ($self->meta->get_method_list) {
        push @res, $1 if /^clause_(.+)/;
    }
    @res;
}

=head2 is_clause($name) -> BOOL

Return true if $name is a valid type clause name.

=cut

sub is_clause {
    my ($self, $name) = @_;
    $self->can("clause_$name") ? 1 : 0;
}

=head2 get_clause_aliases($name) -> ARRAY

Return a list of clause aliases (including itself). The first element is the
canonical name.

=cut

sub get_clause_aliases {
    my ($self, $name) = @_;
    my $re = qr/^clausealias_(.+?)__(.+)$/;
    my @m = grep { /$re/ } $self->meta->get_method_list;
    my $canon;
    for (@m) {
        /$re/;
        if ($1 eq $name || $2 eq $name) { $canon = $1; last }
    }
    return () unless $canon;
    my @res = ($canon);
    for (@m) {
        /$re/;
        push @res, $2 if $1 eq $canon;
    }
    @res;
}

=head1 CLAUSES

If not specified, clause priority is assumed to be 50 (default). The higher the
priority, the smaller the number.

=cut

=head2 default

Supply a default value.

Priority: 1 (very high). This is processed before all other clauses.

Given schema [int => {req=>1}] an undef data is invalid, but given schema [int
=> {req=>1, default=>3}] an undef data is valid because it will be given default
value first.

=cut

clause 'default', prio => 1, arg => 'any';

=head2 SANITY

This is a "hidden" clause that cannot be specified in schemas (due to uppercase
spelling), but emitters use them to add checks.

Priority: 50 (default). Due to its spelling, by sorting, it will be processed
before all other normal clauses.

=cut

clause 'SANITY', arg => 'any';

=head2 PREPROCESS

This is a "hidden" clause that cannot be specified in schemas (due to uppercase
spelling), but emitters can use them to preprocess data before further checking
(for example, Perl emitter for the C<datetime> type can convert string data to
L<DateTime> object). Priority: 5 (very high), executed after B<default> and
B<req>/B<forbidden>.

=cut

clause 'PREPROCESS', arg => 'any', prio => 5;

=head2 req

If set to 1, require that data be defined. Otherwise, allow undef (the default
behaviour).

Priority: 3 (very high), executed after B<default>.

By default, undef will pass even elaborate schema, e.g. [int => {min=>0,
max=>10, div_by=>3}] will still pass an undef. However, undef will not pass
[int=>{req=>1}].

This behaviour is much like NULLs in SQL: we *can't* (in)validate something that
is unknown/unset.

See also: B<forbidden>

=cut

clause 'req', prio => 3, arg => 'bool';

=head2 forbidden

This is the opposite of B<req>, requiring that data be not defined (i.e. undef).

Priority: 3 (very high), executed after B<default>.

Given schema [int=>{forbidden=>1}], a non-undef value will fail. Another
example: the schema [int=>{req=>1, forbidden=>1}] will always fail due to
conflicting clauses.

See also: B<req>

=cut

clause 'forbidden', prio => 3, arg => 'bool';

=head2 deps => [[SCHEMA1, SCHEMA2], [SCHEMA1B, SCHEMA2B], ...]

If data matches SCHEMA1, then data must also match SCHEMA2, and so on. This is
not unlike an if-elsif statement. The clause will fail if any of the condition
is not met.

Example:

 [either => {
   set => 1,
   of => [qw/str array hash/],
   deps => [
     [str   => [str   => {min_len => 1}]],
     [array => [array => {min_len => 1, of => "str"}]],
     [hash  => [hash  => {values_of => "str"}]],
   ]}
 ]

The above schema states: data can be a string, array, or hash. If it is a
string, it must have a nonzero length. If it is an array, it must be a
nonzero-length array of strings. If it is a hash then all values must be
strings.

=cut

clause 'deps',
    arg     => [array => {req=>1, of => '[schema*, schema*]'}];

=head2 prefilters => [EXPR, ...]

Run expression(s), usually to preprocess data before further checking. Data is
refered in expression by variable C<$.> (XXX or C<$data:.>? not yet fixed).

Priority: 10 (high). Run after B<default> and B<req>/B<forbidden> (and
B<PREPROCESS>).

=cut

clause 'prefilters', prio => 10, arg => '((expr*)[])*';

=head2 postfilters => [EXPR, ...]

Run expression(s), usually to postprocess data (XXX for what?)

Priority: 90 (very low). Run after all other clauses.

=cut

clause 'postfilters', prio => 90, arg => '((expr*)[])*';

=head2 lang => LANG

Set language, e.g. 'en'

Priority: 2 (very high)

=cut

clause 'lang', prio => 2, arg => 'str*';

=head2 check => EXPR

Evaluate expression, which must evaluate to a true value for this clause to
succeed.

=cut

clause 'check', arg => 'expr*';

1;
