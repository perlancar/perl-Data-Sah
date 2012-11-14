package Data::Sah::Type::Sortable;

use Moo::Role;
use Data::Sah::Util::Role 'has_clause';

# VERSION

requires 'superclause_sortable';

has_clause 'min',
    arg     => 'any*',
    code    => sub {
        my ($self, $cd) = @_;
        $self->superclause_sortable('min', $cd);
    };

has_clause 'xmin',
    arg     => 'any*',
    code    => sub {
        my ($self, $cd) = @_;
        $self->superclause_sortable('xmin', $cd);
    };

has_clause 'max',
    arg     => 'any*',
    code    => sub {
        my ($self, $cd) = @_;
        $self->superclause_sortable('max', $cd);
    };

has_clause 'xmax',
    arg     => 'any*',
    code    => sub {
        my ($self, $cd) = @_;
        $self->superclause_sortable('xmax', $cd);
    };

has_clause 'between',
    arg  => '[any*, any*]*',
    code => sub {
        my ($self, $cd) = @_;
        $self->superclause_sortable('between', $cd);
    };

has_clause 'xbetween',
    arg  => '[any*, any*]*',
    code => sub {
        my ($self, $cd) = @_;
        $self->superclause_sortable('xbetween', $cd);
    };

1;
# ABSTRACT: Role for sortable types

=head1 DESCRIPTION

Role consumer must provide method C<superclause_sortable> which will receive the
same C<%args> as clause methods, but with additional key: C<-which> (either
C<min>, C<max>, C<xmin>, C<xmax>, C<between>, C<xbetween>).

=cut
