package Data::Sah::Type::Comparable;

# DATE
# VERSION

use Data::Sah::Util::Role 'has_clause';
use Role::Tiny;

requires 'superclause_comparable';

has_clause 'in',
    tags       => ['constraint'],
    arg        => '(any[])*',
    allow_expr => 1,
    code       => sub {
        my ($self, $cd) = @_;
        $self->superclause_comparable('in', $cd);
    };
has_clause 'is',
    tags       => ['constraint'],
    arg        => 'any',
    allow_expr => 1,
    code       => sub {
        my ($self, $cd) = @_;
        $self->superclause_comparable('is', $cd);
    };

1;
# ABSTRACT: Comparable type role

=for Pod::Coverage ^(clause_.+|clausemeta_.+)$

=head1 DESCRIPTION

Role consumer must provide method C<superclause_comparable> which will be given
normal C<%args> given to clause methods, but with extra key C<-which> (either
C<in>, C<is>).

=cut
