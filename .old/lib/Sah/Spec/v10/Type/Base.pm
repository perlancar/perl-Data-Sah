package Data::Schema::Spec::v10::Type::Base;
# ABSTRACT: Specification for base type

=head1 DESCRIPTION

This is the specification for the base type. All types have the attributes
specified below.

=cut

use Any::Moose '::Role';
use Data::Schema::Util 'attr', 'attr_conflict';

# this must not be redefined by subrole or consumer class

=head1 METHODS

=cut

=head2 list_attrs() -> ARRAY

Return list of known type attribute names.

=cut

sub list_attrs {
    my ($self) = @_;
    my @res;
    for ($self->meta->get_method_list) {
        push @res, $1 if /^attr_(.+)/;
    }
    @res;
}

=head2 is_attr($name) -> BOOL

Return true if $name is a valid type attribute name.

=cut

sub is_attr {
    my ($self, $name) = @_;
    $self->can("attr_$name") ? 1 : 0;
}

=head2 get_attr_aliases($name) -> ARRAY

Return a list of attribute aliases (including itself). The first element is the
canonical name.

=cut

sub get_attr_aliases {
    my ($self, $name) = @_;
    my $re = qr/^attralias_(.+?)__(.+)$/;
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

=head1 TYPE ATTRIBUTES

If not specified, attribute priority is assumed to be 50 (default). The higher
the priority, the smaller the number.

=cut

=head2 default

Supply a default value.

Priority: 1 (very high). This is processed before all other attributes.

 ds_validate(undef, [int => {required=>1}]); # invalid, data undefined
 ds_validate(undef, [int => {required=>1, default=>3}]); # valid

=cut

attr 'default', prio => 1, arg => 'any';

=head2 SANITY

This is a "hidden" attribute that cannot be specified in schemas (due to
uppercase spelling), but emitters use them to add checks.

Priority: 50 (default). Due to its spelling, by sorting, it will be processed
before all other normal attributes.

=cut

attr 'SANITY', arg => 'any';

=head2 PREPROCESS

This is a "hidden" attribute that cannot be specified in schemas (due to
uppercase spelling), but emitters can use them to preprocess data before further
checking (for example, Perl emitter for the C<datetime> type can convert string
data to L<DateTime> object). Priority: 5 (very high), executed after B<default>
and B<required>/B<forbidden>/B<set>.

=cut

attr 'PREPROCESS', arg => 'any', prio => 5;

=head2 required

Aliases: B<set> => 1

If set to 1, require that data be defined. Otherwise, allow undef (the default
behaviour).

Priority: 3 (very high), executed after B<default>.

By default, undef will pass even elaborate schema:

 ds_validate(undef, "int"); # valid
 ds_validate(undef, [int => {min=>0, max=>10, divisible_by=>3}]); # valid!

However:

 ds_validate(undef, [int=>{required=>1}]); # invalid

This behaviour is much like NULLs in SQL: we *can't* (in)validate something that
is unknown/unset.

=cut

attr 'required', prio => 3, arg => 'bool';

=head2 forbidden

Aliases: B<set> => 0

This is the opposite of required, requiring that data be not defined (i.e.
undef).

Priority: 3 (very high), executed after B<default>.

 ds_validate(1, [int=>{forbidden=>1}]); # invalid
 ds_validate(undef, [int=>{forbidden=>1}]); # valid

=cut

attr 'forbidden', prio => 3, arg => 'bool';

=head2 set

Alias for required or forbidden. set=>1 equals required=>1, while set=>0 equals
forbidden=>1.

Priority: 3 (very high), executed after B<default>.

=cut

attr 'set', prio => 3, arg => 'bool';

# XXX if set=0, then forbidden=1 or required=0/undef should be allowed
attr_conflict [qw/set forbidden required/];

=head2 deps => [[SCHEMA1, SCHEMA2], [SCHEMA1B, SCHEMA2B], ...]

Aliases: B<dep>

If data matches SCHEMA1, then data must also match SCHEMA2, and so on. This is
not unlike an if-elsif statement. The attribute will fail if any of the condition
is not met.

Example:

 [either => {
   set => 1,
   of => [qw/str array hash/],
   deps => [
     [str   => [str   => {minlen => 1}]],
     [array => [array => {minlen => 1, of => "str"}]],
     [hash  => [hash  => {values_of => "str"}]],
   ]}
 ]

The above schema states: data can be a string, array, or hash. If it is a string,
it must have a nonzero length. If it is an array, it must be a nonzero-length
array of strings. If it is a hash then all values must be strings.

=cut

attr 'deps',
    arg => [array => {set=>1, of => '[schema*, schema*]'}],
    aliases => [qw/dep/];

=head2 prefilters => EXPR|[EXPR, ...]

Run expression(s), usually to preprocess data before further checking. Data is
refered in expression by variable C<$.> (XXX or C<$data:.>? not yet fixed).

Priority: 10 (high). Run after B<default> and B<required>/B<forbidden>/B<set>
(and B<PREPROCESS>).

=cut

attr 'prefilters', prio => 10, arg => 'expr*|((expr*)[])*';

=head2 postfilters => EXPR|[EXPR, ...]

Run expression(s), usually to postprocess data (XXX for what?)

Priority: 90 (very low). Run after all other attributes.

=cut

attr 'postfilters', prio => 90, arg => 'expr*|((expr*)[])*';

=head2 lang => LANG

Set language, e.g. 'en'

Priority: 2 (very high)

=cut

attr 'lang', prio => 2, arg => 'expr*|((expr*)[])*';

=head2 check => EXPR

Alias: B<expr>.

Evaluate expression.

=cut

attr 'check',
    arg => 'str*',
    aliases => [qw/expr/];

no Any::Moose;
1;
