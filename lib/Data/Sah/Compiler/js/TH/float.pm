package Data::Sah::Compiler::js::TH::float;

# DATE
# VERSION

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Mo qw(build default);
use Role::Tiny::With;

extends 'Data::Sah::Compiler::js::TH::num';
with 'Data::Sah::Type::float';

sub handle_type {
    my ($self, $cd) = @_;
    my $c = $self->compiler;
    my $dt = $cd->{data_term};

    $cd->{_ccl_check_type} = "(typeof($dt)=='number' || parseFloat($dt)==$dt)";
}

sub clause_is_nan {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    if ($cd->{cl_is_expr}) {
        $c->add_ccl(
            $cd,
            join(
                "",
                "$ct ? isNaN($dt) : ",
                $self->expr_defined($ct), " ? !isNaN($dt) : true",
            )
        );
    } else {
        if ($cd->{cl_value}) {
            $c->add_ccl($cd, "isNaN($dt)");
        } elsif (defined $cd->{cl_value}) {
            $c->add_ccl($cd, "!isNaN($dt)");
        }
    }
}

sub clause_is_pos_inf {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    if ($cd->{cl_is_expr}) {
        $c->add_ccl(
            $cd,
            join(
                "",
                "$ct ? $dt == Infinity : ",
                $self->expr_defined($ct), " ? $dt != Infinity : true",
            )
        );
    } else {
        if ($cd->{cl_value}) {
            $c->add_ccl($cd, "$dt == Infinity");
        } elsif (defined $cd->{cl_value}) {
            $c->add_ccl($cd, "$dt != Infinity");
        }
    }
}

sub clause_is_neg_inf {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    if ($cd->{cl_is_expr}) {
        $c->add_ccl(
            $cd,
            join(
                "",
                "$ct ? $dt == -Infinity : ",
                $self->expr_defined($ct), " ? $dt != -Infinity : true",
            )
        );
    } else {
        if ($cd->{cl_value}) {
            $c->add_ccl($cd, "$dt == -Infinity");
        } elsif (defined $cd->{cl_value}) {
            $c->add_ccl($cd, "$dt != -Infinity");
        }
    }
}

sub clause_is_inf {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    if ($cd->{cl_is_expr}) {
        $c->add_ccl(
            $cd,
            join(
                "",
                "$ct ? Math.abs($dt) == Infinity : ",
                $self->expr_defined($ct), " ? Math.abs($dt) != Infinity : true",
            )
        );
    } else {
        if ($cd->{cl_value}) {
            $c->add_ccl($cd, "Math.abs($dt) == Infinity");
        } elsif (defined $cd->{cl_value}) {
            $c->add_ccl($cd, "Math.abs($dt) != Infinity");
        }
    }
}

1;
# ABSTRACT: js's type handler for type "float"

=for Pod::Coverage ^(compiler|clause_.+|handle_.+)$
