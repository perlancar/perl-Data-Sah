package Data::Schema::Spec::v10::Type::Sortable;
# ABSTRACT: Specification for sortable types

=head1 DESCRIPTION

This is the sortable role. It provides attributes like less_than (lt),
greater_than (gt), etc. It is used by many types, for example 'str', all numeric
types, etc.

Role consumer must provide method 'mattr_sortable' which takes two arguments:
attribute value, and a string containing 'ge', 'gt', 'le', 'lt'.

=cut

use Any::Moose '::Role';
use Data::Schema::Util 'attr';

requires 'mattr_sortable';

=head1 TYPE ATTRIBUTES

=head2 ge => VAL

Aliases: B<min>

Require that the value is not less than some specified minimum.

=cut

attr 'ge',
    arg => 'any*',
    aliases => 'min',
    sub => sub {
        my ($self, %args) = @_;
        $self->mattr_sortable(%args, which => 'ge');
    };

=head2 gt => MIN

Aliases: B<minex>

Require that the value is not less or equal than some specified minimum.

=cut

attr 'gt',
    arg => 'any*',
    aliases => 'minex',
    sub => sub {
        my ($self, %args) = @_;
        $self->mattr_sortable(%args, which => 'gt');
    };

=head2 le => MAX

Aliases: B<max>

Require that the value is less or equal than some specified maximum.

=cut

attr 'le',
    arg => 'any*',
    aliases => 'max',
    sub => sub {
        my ($self, %args) = @_;
        $self->mattr_sortable(%args, which => 'le');
    };

=head2 lt => MAX

Aliases: B<maxex>

Require that the value is less than some specified maximum.

=cut

attr 'lt',
    arg => 'any*',
    aliases => 'maxex',
    sub => sub {
        my ($self, %args) = @_;
        $self->mattr_sortable(%args, which => 'lt');
    };

=head2 between => [MIN, MAX]

A convenient attribut to combine B<min> and B<max>.

=cut

attr 'between',
    arg => '[any*, any*]*',
    sub => sub {
        my ($self, %args) = @_;
        $self->mattr_sortable(%args, which => 'between');
    };

no Any::Moose;
1;
