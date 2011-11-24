package Data::Sah::Type::Comparable;

use Moo::Role;
use Data::Sah::Util 'has_clause';

requires 'superclause_comparable';

has_clause 'in',
    arg     => '(any[])*',
    code    => sub {
        my ($self, %args) = @_;
        $self->superclause_comparable(%args, -which => 'in');
    };

has_clause 'not_in',
    arg     => '(any[])*',
    code    => sub {
        my ($self, %args) = @_;
        $self->superclause_comparable(%args, -which => 'not_in');
    };

has_clause 'is',
    arg  => 'any',
    code => sub {
        my ($self, %args) = @_;
        $self->superclause_comparable(%args, -which => 'is');
    };

has_clause 'isnt',
    arg     => 'any',
    code    => sub {
        my ($self, %args) = @_;
        $self->superclause_comparable(%args, -which => 'isnt');
    };

1;
# ABSTRACT: Specification for comparable types

=head1 DESCRIPTION

This is the specification for comparable types. It provides clauses like B<is>,
B<in>, etc. It is used by most types, for example 'str', all numeric types, etc.

Role consumer must provide method 'superclause_comparable' which will be given
normal %args given to clause methods, but with extra key -which (either 'in',
'not_in', 'is', 'not').


=head1 CLAUSES

=head2 in => [VALUE, ...]

Require that the data be one of the specified choices.

See also: B<not_in>, B<match> (for type 'str')

Example:

 [int => {in => [1, 2, 3, 4, 5, 6]} # single dice throw value

=head2 not_in => [VALUE, ...]

Require that the data be not listed in one of the specified "blacklists".

See also: B<in>, B<match> (for type 'str')

Example:

 [str => {not_in => ['root', 'admin', 'administrator']}] # forbidden usernames

=head2 is => VALUE

Require that the data is the same as VALUE. Will perform a numeric comparison
for numeric types, or stringwise for string types, or deep comparison for deep
structures.

See also: B<isnt>

=head2 isnt => value

Require that the data is not the same as VALUE.

See also: B<is>

=cut
