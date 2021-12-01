package Data::Sah::Compiler::human::TH::HasElems;

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Mo qw(build default);
use Role::Tiny;
use Role::Tiny::With;

with 'Data::Sah::Type::HasElems';

# AUTHORITY
# DATE
# DIST
# VERSION

sub before_clause {
    my ($self_th, $which, $cd) = @_;
}

sub before_clause_len_between {
    my ($self, $cd) = @_;
    $cd->{CLAUSE_DO_MULTI} = 0;
}

sub superclause_has_elems {
    my ($self_th, $which, $cd) = @_;
    my $c  = $self_th->compiler;
    my $cv = $cd->{cl_value};

    if ($which eq 'len') {
        $c->add_ccl($cd, {
            expr  => 1,
            fmt   => q[length %(modal_verb)s be %s],
        });
    } elsif ($which eq 'min_len') {
        $c->add_ccl($cd, {
            expr  => 1,
            fmt   => q[length %(modal_verb)s be at least %s],
        });
    } elsif ($which eq 'max_len') {
        $c->add_ccl($cd, {
            expr  => 1,
            fmt   => q[length %(modal_verb)s be at most %s],
        });
    } elsif ($which eq 'len_between') {
        $c->add_ccl($cd, {
            fmt   => q[length %(modal_verb)s be between %s and %s],
            vals  => $cv,
        });
    } elsif ($which eq 'has') {
        $c->add_ccl($cd, {
            expr=>1, multi=>1,
            fmt => "%(modal_verb)s have %s in its elements"});
    } elsif ($which eq 'each_index') {
        $self_th->clause_each_index($cd);
    } elsif ($which eq 'each_elem') {
        $self_th->clause_each_elem($cd);
    } elsif ($which eq 'check_each_index') {
        $self_th->compiler->_die_unimplemented_clause($cd);
    } elsif ($which eq 'check_each_elem') {
        $self_th->compiler->_die_unimplemented_clause($cd);
    } elsif ($which eq 'uniq') {
        $self_th->compiler->_die_unimplemented_clause($cd);
    } elsif ($which eq 'exists') {
        $self_th->compiler->_die_unimplemented_clause($cd);
    }
}

1;
# ABSTRACT: human's type handler for role "HasElems"

=for Pod::Coverage ^(name|clause_.+|superclause_.+|before_.+|after_.+)$
