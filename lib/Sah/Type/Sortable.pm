package Sah::Type::Sortable;
# ABSTRACT: Specification for sortable types

=head1 DESCRIPTION

This is the sortable role. It provides clauses like less_than (lt), greater_than
(gt), etc. It is used by many types, for example 'str', all numeric types, etc.

Role consumer must provide method 'metaclause_sortable' which will receive the
same %args as clause methods, but with additional key: -which (either 'ge', 'gt',
'le', 'lt').

=cut

use Any::Moose '::Role';
use Sah::Util 'clause';

requires 'metaclause_sortable';

=head1 CLAUSES

=head2 ge => VAL

Aliases: B<min>, B<minimum>

Require that the value is not less than some specified minimum.

=cut

clause 'ge',
    arg     => 'any*',
    aliases => ['min', 'minimum'],
    code    => sub {
        my ($self, %args) = @_;
        $self->metaclause_sortable(%args, -which => 'ge');
    };

=head2 gt => MIN

Aliases: B<minex>

Require that the value is not less or equal than some specified minimum.

=cut

clause 'gt',
    arg     => 'any*',
    aliases => 'minex',
    code => sub {
        my ($self, %args) = @_;
        $self->metaclause_sortable(%args, -which => 'gt');
    };

=head2 le => MAX

Aliases: B<max>, B<maximum>

Require that the value is less or equal than some specified maximum.

=cut

clause 'le',
    arg     => 'any*',
    aliases => ['max', 'maximum'],
    code    => sub {
        my ($self, %args) = @_;
        $self->metaclause_sortable(%args, -which => 'le');
    };

=head2 lt => MAX

Aliases: B<maxex>

Require that the value is less than some specified maximum.

=cut

clause 'lt',
    arg     => 'any*',
    aliases => 'maxex',
    code    => sub {
        my ($self, %args) = @_;
        $self->metaclause_sortable(%args, -which => 'lt');
    };

=head2 between => [MIN, MAX]

A convenient clause to combine B<min> and B<max>.

=cut

clause 'between',
    arg  => '[any*, any*]*',
    code => sub {
        my ($self, %args) = @_;
        $self->metaclause_sortable(%args, -which => 'between');
    };

no Any::Moose;
1;
