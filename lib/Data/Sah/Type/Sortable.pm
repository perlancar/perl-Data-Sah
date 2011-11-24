package Data::Sah::Type::Sortable;

use Moo::Role;
use Data::Sah::Util 'has_clause';

requires 'superclause_sortable';

has_clause 'min',
    arg     => 'any*',
    code    => sub {
        my ($self, %args) = @_;
        $self->superclause_sortable(%args, -which => 'min');
    };

has_clause 'xmin',
    arg     => 'any*',
    code    => sub {
        my ($self, %args) = @_;
        $self->superclause_sortable(%args, -which => 'xmin');
    };

has_clause 'max',
    arg     => 'any*',
    code    => sub {
        my ($self, %args) = @_;
        $self->superclause_sortable(%args, -which => 'max');
    };

has_clause 'xmax',
    arg     => 'any*',
    code    => sub {
        my ($self, %args) = @_;
        $self->superclause_sortable(%args, -which => 'xmax');
    };

has_clause 'between',
    arg  => '[any*, any*]*',
    code => sub {
        my ($self, %args) = @_;
        $self->superclause_sortable(%args, -which => 'between');
    };

has_clause 'xbetween',
    arg  => '[any*, any*]*',
    code => sub {
        my ($self, %args) = @_;
        $self->superclause_sortable(%args, -which => 'xbetween');
    };

1;
# ABSTRACT: Specification for sortable types

=head1 DESCRIPTION

This is the Sortable role. It provides clauses like 'lt' ("less than"), 'gt'
("greater than"), and so on. It is used by many types, for example 'str', all
numeric types, etc.

Role consumer must provide method 'superclause_sortable' which will receive the
same %args as clause methods, but with additional key: -which (either 'min',
'max', 'xmin', 'xmax').


=head1 CLAUSES

Unless specified otherwise, all clauses have a priority of 50 (normal).

=head2 min => VALUE

Require that the value is not less than some specified minimum (equivalent in
intention to the Perl string 'ge' operator, or the numeric >= operator).

Example:

 [int => {min => 0}] # specify positive numbers

=head2 xmin => VALUE

Require that the value is not less nor equal than some specified minimum
(equivalent in intention to the Perl string 'gt' operator, or the numeric >
operator). The "x" prefix is for "exclusive".

=head2 max => VALUE

Require that the value is less or equal than some specified maximum (equivalent
in intention to the Perl string 'le' operator, or the numeric <= operator).

=head2 xmax => VALUE

Require that the value is less than some specified maximum (equivalent in
intention to the Perl string 'lt' operator, or the numeric < operator). The "x"
prefix is for "exclusive".

=head2 between => [MIN, MAX]

A convenient clause to combine B<min> and B<max>.

Example, the following schemas are equivalent:

 [float => {between => [0.0, 1.5]}]
 [float => {min => 0.0, max => 1.5}]

=head2 xbetween => [MIN, MAX]

A convenient clause to combine B<xmin> and B<xmax>.

=cut
