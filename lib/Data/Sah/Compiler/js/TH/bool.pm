package Data::Sah::Compiler::js::TH::bool;

# DATE
# VERSION

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Mo qw(build default);
use Role::Tiny::With;

extends 'Data::Sah::Compiler::js::TH';
with 'Data::Sah::Type::bool';

sub handle_type {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    my $dt = $cd->{data_term};
    $cd->{_ccl_check_type} = "typeof($dt)=='boolean' || typeof($dt)=='number' || typeof($dt)=='string'";
}

sub superclause_comparable {
    my ($self, $which, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    if ($which eq 'is') {
        $c->add_ccl($cd, "!!($dt) == !!($ct)");
    } elsif ($which eq 'in') {
        $c->add_ccl($cd, "($ct).map(function(x){return !!x}).indexOf(!!($dt)) > -1");
    }
}

sub superclause_sortable {
    my ($self, $which, $cd) = @_;
    my $c  = $self->compiler;
    my $cv = $cd->{cl_value};
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    if ($which eq 'min') {
        $c->add_ccl($cd, "!!($dt) >= !!($ct)");
    } elsif ($which eq 'xmin') {
        $c->add_ccl($cd, "!!($dt) > !!($ct)");
    } elsif ($which eq 'max') {
        $c->add_ccl($cd, "!!($dt) <= !!($ct)");
    } elsif ($which eq 'xmax') {
        $c->add_ccl($cd, "!!($dt) < !!($ct)");
    } elsif ($which eq 'between') {
        if ($cd->{cl_is_expr}) {
            $c->add_ccl($cd, "!!($dt) >= !!($ct\->[0]) && ".
                            "!!($dt) <= !!($ct\->[1])");
        } else {
            # simplify code
            $c->add_ccl($cd, "!!($dt) >= !!($cv->[0]) && ".
                            "!!($dt) <= !!($cv->[1])");
        }
    } elsif ($which eq 'xbetween') {
        if ($cd->{cl_is_expr}) {
            $c->add_ccl($cd, "!!($dt) > !!($ct\->[0]) && ".
                            "!!($dt) < !!($ct\->[1])");
        } else {
            # simplify code
            $c->add_ccl($cd, "!!($dt) > !!($cv->[0]) && ".
                            "!!($dt) < !!($cv->[1])");
        }
    }
}

sub clause_is_true {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    $c->add_ccl($cd, "$ct ? !!($dt) : !(".$c->expr_defined($ct).") ? true : !($dt)");
}

1;
# ABSTRACT: js's type handler for type "bool"

=for Pod::Coverage ^(clause_.+|superclause_.+)$
