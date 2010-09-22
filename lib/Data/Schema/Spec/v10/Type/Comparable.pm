package Data::Schema::Spec::v10::Type::Comparable;
# ABSTRACT: Specification for comparable types

=head1 DESCRIPTION

This is the specification for comparable types. It provides attributes like
B<is>, B<one_of>, etc. It is used by most types, for example 'str', all numeric
types, etc.

Role consumer must provide method 'mattr_comparable' which takes two arguments:
attribute value and a string containing 'is', 'one_of', 'isnt', and 'not_one_of'.

=cut

use Any::Moose '::Role';
use Data::Schema::Util 'attr';

requires 'mattr_comparable';

=head1 TYPE ATTRIBUTES

=head2 one_of => [VALUE1, ...]

Aliases: B<is_one_of>, B<in>

Require that the data be one of the specified choices.

=cut

attr 'one_of',
    aliases => [qw/is_one_of in/],
    arg => '(any[])*',
    sub => sub {
        my ($self, %args) = @_;
        $self->mattr_comparable(%args, which => 'one_of');
    };

=head2 not_one_of => [value1, ...]

Aliases: B<isnt_one_of>, B<not_in>

Require that the data be not listed in one of the specified "blacklists".

=cut

attr 'not_one_of',
    aliases => [qw/isnt_one_of not_in/],
    arg => '(any[])*',
    sub => sub {
        my ($self, %args) = @_;
        $self->mattr_comparable(%args, which => 'not_one_of');
    };

=head2 is => value

A convenient attribute for B<one_of> when there is only one choice.

=cut

attr 'is',
    arg => 'any',
    sub => sub {
        my ($self, %args) = @_;
        $self->mattr_comparable(%args, which => 'is');
    };

=head2 isnt => value

Aliases: B<not>

A convenient attribute for B<not_one_of> when there is only one item in the
blacklist.

=cut

attr 'isnt',
    arg => 'any',
    aliases => [qw/not/],
    sub => sub {
        my ($self, %args) = @_;
        $self->mattr_comparable(%args, 'isnt');
    };

no Any::Moose;
1;
