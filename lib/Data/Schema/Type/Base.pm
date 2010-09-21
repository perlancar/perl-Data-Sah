package Data::Schema::Type::Base;
# ABSTRACT: Specification for base type

=head1 DESCRIPTION

This is the specification for the base type. All types have the
attributes specified below.

=cut

use Any::Moose '::Role';
use Data::Schema::Util 'attr', 'attr_conflict';

# this must not be redefined by subrole or consumer class

=head1 TYPE ATTRIBUTES

=cut

attr 'SANITY', arg => 'any';

=head2 default

Supply a default value.

 ds_validate(undef, [int => {required=>1}]); # invalid, data undefined
 ds_validate(undef, [int => {required=>1, default=>3}]); # valid

=cut

attr 'default', prio => 1, arg => 'any';

=head2 required

Aliases: B<set> => 1

If set to 1, require that data be defined. Otherwise, allow undef (the
default behaviour).

By default, undef will pass even elaborate schema:

 ds_validate(undef, "int"); # valid
 ds_validate(undef, [int => {min=>0, max=>10, divisible_by=>3}]); # valid!

However:

 ds_validate(undef, [int=>{required=>1}]); # invalid

This behaviour is much like NULLs in SQL: we *can't* validate
something that is unknown/unset.

=cut

attr 'required', prio => 3, arg => 'bool';

=head2 forbidden

Aliases: B<set> => 0

This is the opposite of required, requiring that data be not defined (i.e.
undef).

 ds_validate(1, [int=>{forbidden=>1}]); # invalid
 ds_validate(undef, [int=>{forbidden=>1}]); # valid

=cut

attr 'forbidden', prio => 3, arg => 'bool';

=head2 set

Alias for required or forbidden. set=>1 equals required=>1, while set=>0
equals forbidden=>1.

=cut

attr 'set', prio => 3, arg => 'bool';

# XXX if set=0, then forbidden=1 or required=0/undef should be allowed
attr_conflict [qw/set forbidden required/];

=head2 deps => [[SCHEMA1, SCHEMA2], [SCHEMA1B, SCHEMA2B], ...]

Aliases: B<dep>

If data matches SCHEMA1, then data must also match SCHEMA2.

This is not unlike an if-elsif statement.

See also L<Data::Schema::Type::Either> where you can also write
attribute 'of' => [SCHEMA1, SCHEMA1B, ...]. But the disadvantage of
the 'of' attribute of 'either' type is it does not report validation
error details for SCHEMA2, SCHEMA2B, etc. It just report that data
does not match any of SCHEMA1/SCHEMA1B/...

Example:

 [either => {
   set => 1,
   of => [qw/str array hash/],
   deps => [
     [str   => [str   => {one_of => [qw/str string int float .../]}]],
     [array => [array => {minlen => 2, ...}]],
     [hash  => [hash  => {keys => {type => ..., def => ..., attr_hashes => ...}}]]
   ]}
 ]

The above schema is actually from DS schema. A schema can be str
(first form), array (second form), or hash (third form). For each form, we
define further validation in the 'deps' attribute.

=cut

attr 'deps',
    arg => [array => {set=>1, of => '[schema*, schema*]'}],
    aliases => [qw/dep/];

=head2 prefilters => EXPR|[EXPR, ...]

XXX Run EXPR

=cut

attr 'prefilters', prio => 2, arg => 'expr*|((expr*)[])*';

=head2 postfilters => EXPR|[EXPR, ...]

XXX Run EXPR

=cut

attr 'postfilters', prio => 98, arg => 'expr*|((expr*)[])*';

=head2 lang => LANG

Set language, e.g. 'en'

=cut

attr 'lang', prio => 1, arg => 'expr*|((expr*)[])*';

=head2 either => {attr => ATTR[, props => PROPS], values =>[...]}

Alias: B<any>, B<or>.

Execute an attribute with several values. Only one needs to succeed.

Example:

 [str => {minlen => 1,
          either => [attr => 'match', values => [qr/^\w+$/, qr/^b4ck d00r$/],
         }]

In the above example, data needs to be a string entirely composed of
alphanumeric characters, or a special string 'b4ck d00r'. This can
also be specified using the B<either> I<type>:

 [either => {
    of => [
      ['str*' => {minlen => 1, match => qr/^\w+$/}],
      ['str*' => {is => 'b4ck d00r'}],
    ]
 }]

See also: B<all>, L<Data::Schema::Type::Either> (B<either> type).

=cut

attr 'either',
    arg => ['hash*' => {required_keys => ['attr', 'values'],
                        keys => {
                            attr => 'str*', # XXX check attribute name syntax
                            values => 'array*',
                        }
                    }],
    aliases => [qw/or any/];

=head2 all => {attr => ATTR[, props => PROPS], values =>[...]}

Alias: B<and>.

Just like B<all>, but every value needs to succeed.

See also: B<either>, L<Data::Schema::Type::Either> (B<either> type).

=cut

attr 'all',
    arg => ['hash*' => {required_keys => ['attr', 'values'],
                        keys => {
                            attr => 'str*', # XXX check attribute name syntax
                            values => 'array*',
                        }
                    }],
    aliases => [qw/and/];

=head2 check => EXPR

Alias: B<expr>.

Evaluate expression.

=cut

attr 'check',
    arg => 'str*',
    aliases => [qw/expr/];

no Any::Moose;
1;
