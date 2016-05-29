package Data::Sah::Type::Comparable;

# DATE
# VERSION

use Data::Sah::Util::Role 'has_clause';
use Role::Tiny;

requires 'superclause_comparable';

has_clause 'in',
    v => 2,
    tags       => ['constraint'],
    arg        => ['array', {req=>1, of=>['_same', {req=>1}, {}]}, {}],
    allow_expr => 1,
    code       => sub {
        my ($self, $cd) = @_;
        $self->superclause_comparable('in', $cd);
    };
has_clause 'is',
    v => 2,
    tags       => ['constraint'],
    arg        => ['_same', {req=>1}, {}],
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
