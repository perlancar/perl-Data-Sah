package Data::Sah::Type::Sortable;
# ABSTRACT: Specification for sortable types

=head1 DESCRIPTION

This is the sortable role. It provides clauses like less_than (lt), greater_than
(gt), etc. It is used by many types, for example 'str', all numeric types, etc.

Role consumer must provide method 'superclause_sortable' which will receive the
same %args as clause methods, but with additional key: -which (either 'min',
'max', 'minex', 'maxex').

=cut

use Moo::Role;
use Data::Sah::Util 'clause';

requires 'superclause_sortable';

=head1 CLAUSES

=head2 min => VALUE

Require that the value is not less than some specified minimum (equivalent in
intention to the Perl string 'ge' operator, or the numeric >= operator).

=cut

clause 'min',
    arg     => 'any*',
    code    => sub {
        my ($self, %args) = @_;
        $self->superclause_sortable(%args, -which => 'min');
    };

=head2 minex => VALUE

Require that the value is not less nor equal than some specified minimum
(equivalent in intention to the Perl string 'gt' operator, or the numeric >
operator).

=cut

clause 'minex', arg => 'any*', code => sub { my ($self, %args) = @_;
    $self->superclause_sortable(%args, -which => 'minex'); };

=head2 max => VALUE

Require that the value is less or equal than some specified maximum (equivalent
in intention to the Perl string 'le' operator, or the numeric <= operator).

=cut

clause 'max',
    arg     => 'any*',
    code    => sub {
        my ($self, %args) = @_;
        $self->superclause_sortable(%args, -which => 'max');
    };

=head2 maxex => VALUE

Require that the value is less than some specified maximum (equivalent in
intention to the Perl string 'lt' operator, or the numeric < operator).

=cut

clause 'maxex',
    arg     => 'any*',
    aliases => 'maxex',
    code    => sub {
        my ($self, %args) = @_;
        $self->superclause_sortable(%args, -which => 'maxex');
    };

=head2 between => [MIN, MAX]

A convenient clause to combine B<min> and B<max>.

=cut

clause 'between',
    arg  => '[any*, any*]*',
    code => sub {
        my ($self, %args) = @_;
        $self->superclause_sortable(%args, -which => 'between');
    };

1;
