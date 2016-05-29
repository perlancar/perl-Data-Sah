package Data::Sah::Type::Sortable;

# DATE
# VERSION

use Data::Sah::Util::Role 'has_clause';
use Role::Tiny;

requires 'superclause_sortable';

has_clause 'min',
    v => 2,
    tags       => ['constraint'],
    arg        => ['_same', {req=>1}, {}],
    allow_expr => 1,
    code       => sub {
        my ($self, $cd) = @_;
        $self->superclause_sortable('min', $cd);
    },
    ;
has_clause 'xmin',
    v => 2,
    tags       => ['constraint'],
    arg        => ['_same', {req=>1}, {}],
    allow_expr => 1,
    code       => sub {
        my ($self, $cd) = @_;
        $self->superclause_sortable('xmin', $cd);
    },
    ;
has_clause 'max',
    v => 2,
    prio       => 51,
    tags       => ['constraint'],
    arg        => ['_same', {req=>1}, {}],
    allow_expr => 1,
    code       => sub {
        my ($self, $cd) = @_;
        $self->superclause_sortable('max', $cd);
    },
    ;
has_clause 'xmax',
    v => 2,
    prio       => 51,
    tags       => ['constraint'],
    arg        => ['_same', {req=>1}, {}],
    allow_expr => 1,
    code       => sub {
        my ($self, $cd) = @_;
        $self->superclause_sortable('xmax', $cd);
    },
    ;
has_clause 'between',
    v => 2,
    tags       => ['constraint'],
    arg        => ['array', {req=>1, len=>2, elems=>[
        ['_same', {req=>1}, {}],
        ['_same', {req=>1}, {}],
    ]}, {}],
    allow_expr => 1,
    code       => sub {
        my ($self, $cd) = @_;
        $self->superclause_sortable('between', $cd);
    },
    ;
has_clause 'xbetween',
    v => 2,
    tags       => ['constraint'],
    arg        => ['array', {req=>1, len=>2, elems=>[
        ['_same', {req=>1}, {}],
        ['_same', {req=>1}, {}],
    ]}, {}],
    allow_expr => 1,
    code => sub {
        my ($self, $cd) = @_;
        $self->superclause_sortable('xbetween', $cd);
    },
    ;

1;
# ABSTRACT: Role for sortable types

=for Pod::Coverage ^(clause_.+|clausemeta_.+)$

=head1 DESCRIPTION

Role consumer must provide method C<superclause_sortable> which will receive the
same C<%args> as clause methods, but with additional key: C<-which> (either
C<min>, C<max>, C<xmin>, C<xmax>, C<between>, C<xbetween>).

=cut
