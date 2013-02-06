package Data::Sah::Compiler::js::TH::num;

use 5.010;
use Log::Any '$log';
use Moo;
extends 'Data::Sah::Compiler::js::TH';
with 'Data::Sah::Type::num';

# VERSION

sub handle_type {
    my ($self, $cd) = @_;
    my $c = $self->compiler;
    my $dt = $cd->{data_term};

    $cd->{_ccl_check_type} = "(typeof($dt)=='number' || parseFloat($dt)==$dt)";
}

sub before_all_clauses {
    my ($self, $cd) = @_;
    my $c = $self->compiler;
    my $dt = $cd->{data_term};

    # XXX only do this when there are clauses

    # convert non-number to number, if we need further testing like <, >=, etc.
    $self->set_tmp_data_term(
        $cd, "typeof($dt)=='number' ? $dt : parseFloat($dt)");
}

sub after_all_clauses {
    my ($self, $cd) = @_;
    my $c = $self->compiler;
    my $dt = $cd->{data_term};

    $self->restore_data_term($cd);
}

sub superclause_comparable {
    my ($self, $which, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    if ($which eq 'is') {
        $c->add_ccl($cd, "$dt == $ct");
    } elsif ($which eq 'in') {
        $c->add_ccl($cd, "($ct).indexOf($dt) > -1");
    }
}

sub superclause_sortable {
    my ($self, $which, $cd) = @_;
    my $c  = $self->compiler;
    my $cv = $cd->{cl_value};
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    if ($which eq 'min') {
        $c->add_ccl($cd, "$dt >= $ct");
    } elsif ($which eq 'xmin') {
        $c->add_ccl($cd, "$dt > $ct");
    } elsif ($which eq 'max') {
        $c->add_ccl($cd, "$dt <= $ct");
    } elsif ($which eq 'xmax') {
        $c->add_ccl($cd, "$dt < $ct");
    } elsif ($which eq 'between') {
        if ($cd->{cl_is_expr}) {
            $c->add_ccl($cd, "$dt >= $ct\[0] && $dt <= $ct\[1]");
        } else {
            # simplify code
            $c->add_ccl($cd, "$dt >= $cv->[0] && $dt <= $cv->[1]");
        }
    } elsif ($which eq 'xbetween') {
        if ($cd->{cl_is_expr}) {
            $c->add_ccl($cd, "$dt > $ct\[0] && $dt < $ct\[1]");
        } else {
            # simplify code
            $c->add_ccl($cd, "$dt > $cv->[0] && $dt < $cv->[1]");
        }
    }
}

1;
# ABSTRACT: js's type handler for type "num"

=for Pod::Coverage ^(clause_.+|superclause_.+|before_.+|after_.+)$
