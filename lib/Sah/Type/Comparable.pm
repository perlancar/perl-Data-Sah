package Sah::Type::Comparable;
# ABSTRACT: Specification for comparable types

=head1 DESCRIPTION

This is the specification for comparable types. It provides clauses like B<is>,
B<one_of>, etc. It is used by most types, for example 'str', all numeric types,
etc.

Role consumer must provide method 'metaclause_comparable' which will be given
normal %args given to clause methods, but with extra key -which (either 'one_of',
'not_one_of', 'is', 'isnt').

=cut

use Any::Moose '::Role';
use Sah::Util 'clause';

requires 'metaclause_comparable';

=head1 CLAUSES

=head2 one_of => [VALUE1, ...]

Aliases: B<is_one_of>, B<in>

Require that the data be one of the specified choices.

=cut

clause 'one_of',
    aliases => [qw/is_one_of in/],
    arg     => '(any[])*',
    code    => sub {
        my ($self, %args) = @_;
        $self->metaclause_comparable(%args, -which => 'one_of');
    };

=head2 not_one_of => [value1, ...]

Aliases: B<isnt_one_of>, B<not_in>

Require that the data be not listed in one of the specified "blacklists".

=cut

clause 'not_one_of',
    aliases => [qw/isnt_one_of not_in/],
    arg     => '(any[])*',
    code    => sub {
        my ($self, %args) = @_;
        $self->metaclause_comparable(%args, -which => 'not_one_of');
    };

=head2 is => value

A convenient clause for B<one_of> when there is only one choice.

=cut

clause 'is',
    arg  => 'any',
    code => sub {
        my ($self, %args) = @_;
        $self->metaclause_comparable(%args, -which => 'is');
    };

=head2 isnt => value

Aliases: B<not>

A convenient clause for B<not_one_of> when there is only one item in the
blacklist.

=cut

clause 'isnt',
    arg     => 'any',
    aliases => [qw/not/],
    code    => sub {
        my ($self, %args) = @_;
        $self->metaclause_comparable(%args, -which => 'isnt');
    };

no Any::Moose;
1;
