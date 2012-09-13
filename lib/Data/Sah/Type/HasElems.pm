package Data::Sah::Type::HasElems;

use Moo::Role;
use Data::Sah::Util 'has_clause';

# VERSION

requires 'superclause_has_elems';

has_clause 'max_len',
    arg     => ['int*' => {min=>0}],
    code    => sub {
        my ($self, $cd) = @_;
        $self->superclause_has_elems('max_len', $cd);
    };

has_clause 'min_len',
    arg     => ['int*' => {min=>0}],
    code    => sub {
        my ($self, $cd) = @_;
        $self->superclause_has_elems('min_len', $cd);
    };

has_clause 'len_between',
    arg   => ['array*' => {elements => ['int*', 'int*']}],
    code  => sub {
        my ($self, $cd) = @_;
        $self->superclause_has_elems('len_between', $cd);
    };

has_clause 'len',
    arg   => ['int*' => {min=>0}],
    code  => sub {
        my ($self, $cd) = @_;
        $self->superclause_has_elems('len', $cd);
    };

has_clause 'has',
    arg => 'any',
    code => sub {
        my ($self, $cd) = @_;
        $self->superclause_has_elems('has', $cd);
    };

has_clause 'if_elems',
    arg => 'schema*',
    code => sub {
        my ($self, $cd) = @_;
        $self->superclause_has_elems('if_elems', $cd);
    };

has_clause 'if_elems_re',
    arg => 'schema*',
    code => sub {
        my ($self, $cd) = @_;
        $self->superclause_has_elems('if_elems_re', $cd);
    };

1;
# ABSTRACT: Role for types that have the notion of elements

=head1 DESCRIPTION

Role consumer must provide method C<superclause_has_elems> which will receive
the same C<%args> as clause methods, but with additional key: C<-which> (either
C<max_len>, C<min_len>, C<len>, C<len_between>, C<has>, C<if_elems>,
C<if_elems_re>).

=cut
