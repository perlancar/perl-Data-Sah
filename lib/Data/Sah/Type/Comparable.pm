package Data::Sah::Type::Comparable;
# ABSTRACT: Specification for comparable types

=head1 DESCRIPTION

This is the specification for comparable types. It provides clauses like B<is>,
B<in>, etc. It is used by most types, for example 'str', all numeric types, etc.

Role consumer must provide method 'superclause_comparable' which will be given
normal %args given to clause methods, but with extra key -which (either 'in',
'not_in', 'is', 'not').

=cut

use Moo::Role;
use Data::Sah::Util 'clause';

requires 'superclause_comparable';

=head1 CLAUSES

=head2 in => [VALUE, ...]

Require that the data be one of the specified choices.

See also: B<not_in>

=cut

clause 'in',
    arg     => '(any[])*',
    code    => sub {
        my ($self, %args) = @_;
        $self->superclause_comparable(%args, -which => 'in');
    };

=head2 not_in => [VALUE, ...]

Require that the data be not listed in one of the specified "blacklists".

See also: B<in>

=cut

clause 'not_in',
    arg     => '(any[])*',
    code    => sub {
        my ($self, %args) = @_;
        $self->superclause_comparable(%args, -which => 'not_in');
    };

=head2 is => VALUE

Require that the data is the same as VALUE. Will perform a numeric comparison for
numeric types, or stringwise for string types, or deep comparison for deep
structures.

See also: B<isnt>

=cut

clause 'is',
    arg  => 'any',
    code => sub {
        my ($self, %args) = @_;
        $self->superclause_comparable(%args, -which => 'is');
    };

=head2 isnt => value

Require that the data is not the same as VALUE.

See also: B<is>

=cut

clause 'isnt',
    arg     => 'any',
    code    => sub {
        my ($self, %args) = @_;
        $self->superclause_comparable(%args, -which => 'isnt');
    };

1;
