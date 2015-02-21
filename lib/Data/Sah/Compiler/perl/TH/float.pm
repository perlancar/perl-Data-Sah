package Data::Sah::Compiler::perl::TH::float;

# DATE
# VERSION

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Mo qw(build default);
use Role::Tiny::With;

extends 'Data::Sah::Compiler::perl::TH::num';
with 'Data::Sah::Type::float';

sub handle_type {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    my $dt = $cd->{data_term};
    $c->add_module($cd, 'Scalar::Util::Numeric');
    # we use isnum = isint + isfloat, because isfloat(3) is false
    $cd->{_ccl_check_type} = "Scalar::Util::Numeric::isnum($dt)";
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
                "$ct ? Scalar::Util::Numeric::isnan($dt) : ",
                "defined($ct) ? !Scalar::Util::Numeric::isnan($dt) : 1",
            )
        );
    } else {
        if ($cd->{cl_value}) {
            $c->add_ccl($cd, "Scalar::Util::Numeric::isnan($dt)");
        } elsif (defined $cd->{cl_value}) {
            $c->add_ccl($cd, "!Scalar::Util::Numeric::isnan($dt)");
        }
    }
}

sub clause_is_neg_inf {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    if ($cd->{cl_is_expr}) {
        $c->add_ccl($cd, "$ct ? Scalar::Util::Numeric::isinf($dt) && Scalar::Util::Numeric::isneg($dt) : ".
                        "defined($ct) ? !(Scalar::Util::Numeric::isinf($dt) && Scalar::Util::Numeric::isneg($dt)) : 1");
    } else {
        if ($cd->{cl_value}) {
            $c->add_ccl($cd, "Scalar::Util::Numeric::isinf($dt) && Scalar::Util::Numeric::isneg($dt)");
        } elsif (defined $cd->{cl_value}) {
            $c->add_ccl($cd, "!(Scalar::Util::Numeric::isinf($dt) && Scalar::Util::Numeric::isneg($dt))");
        }
    }
}

sub clause_is_pos_inf {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    if ($cd->{cl_is_expr}) {
        $c->add_ccl($cd, "$ct ? Scalar::Util::Numeric::isinf($dt) && !Scalar::Util::Numeric::isneg($dt) : ".
                        "defined($ct) ? !(Scalar::Util::Numeric::isinf($dt) && !Scalar::Util::Numeric::isneg($dt)) : 1");
    } else {
        if ($cd->{cl_value}) {
            $c->add_ccl($cd, "Scalar::Util::Numeric::isinf($dt) && !Scalar::Util::Numeric::isneg($dt)");
        } elsif (defined $cd->{cl_value}) {
            $c->add_ccl($cd, "!(Scalar::Util::Numeric::isinf($dt) && !Scalar::Util::Numeric::isneg($dt))");
        }
    }
}

sub clause_is_inf {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    if ($cd->{cl_is_expr}) {
        $c->add_ccl($cd, "$ct ? Scalar::Util::Numeric::isinf($dt) : ".
                        "defined($ct) ? Scalar::Util::Numeric::isinf($dt) : 1");
    } else {
        if ($cd->{cl_value}) {
            $c->add_ccl($cd, "Scalar::Util::Numeric::isinf($dt)");
        } elsif (defined $cd->{cl_value}) {
            $c->add_ccl($cd, "!Scalar::Util::Numeric::isinf($dt)");
        }
    }
}

1;
# ABSTRACT: perl's type handler for type "float"

=for Pod::Coverage ^(compiler|clause_.+|handle_.+)$
