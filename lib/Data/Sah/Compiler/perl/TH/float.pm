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
    $c->add_sun_module($cd);
    # we use isnum = isint + isfloat, because isfloat(3) is false
    $cd->{_ccl_check_type} = "$cd->{_sun_module}::isnum($dt)";
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
                "$ct ? $cd->{_sun_module}::isnan($dt) : ",
                "defined($ct) ? !$cd->{_sun_module}::isnan($dt) : 1",
            )
        );
    } else {
        if ($cd->{cl_value}) {
            $c->add_ccl($cd, "$cd->{_sun_module}::isnan($dt)");
        } elsif (defined $cd->{cl_value}) {
            $c->add_ccl($cd, "!$cd->{_sun_module}::isnan($dt)");
        }
    }
}

sub clause_is_neg_inf {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    if ($cd->{cl_is_expr}) {
        $c->add_ccl($cd, "$ct ? $cd->{_sun_module}::isinf($dt) && $cd->{_sun_module}::isneg($dt) : ".
                        "defined($ct) ? !($cd->{_sun_module}::isinf($dt) && $cd->{_sun_module}::isneg($dt)) : 1");
    } else {
        if ($cd->{cl_value}) {
            $c->add_ccl($cd, "$cd->{_sun_module}::isinf($dt) && $cd->{_sun_module}::isneg($dt)");
        } elsif (defined $cd->{cl_value}) {
            $c->add_ccl($cd, "!($cd->{_sun_module}::isinf($dt) && $cd->{_sun_module}::isneg($dt))");
        }
    }
}

sub clause_is_pos_inf {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    if ($cd->{cl_is_expr}) {
        $c->add_ccl($cd, "$ct ? $cd->{_sun_module}::isinf($dt) && !$cd->{_sun_module}::isneg($dt) : ".
                        "defined($ct) ? !($cd->{_sun_module}::isinf($dt) && !$cd->{_sun_module}::isneg($dt)) : 1");
    } else {
        if ($cd->{cl_value}) {
            $c->add_ccl($cd, "$cd->{_sun_module}::isinf($dt) && !$cd->{_sun_module}::isneg($dt)");
        } elsif (defined $cd->{cl_value}) {
            $c->add_ccl($cd, "!($cd->{_sun_module}::isinf($dt) && !$cd->{_sun_module}::isneg($dt))");
        }
    }
}

sub clause_is_inf {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    if ($cd->{cl_is_expr}) {
        $c->add_ccl($cd, "$ct ? $cd->{_sun_module}::isinf($dt) : ".
                        "defined($ct) ? $cd->{_sun_module}::isinf($dt) : 1");
    } else {
        if ($cd->{cl_value}) {
            $c->add_ccl($cd, "$cd->{_sun_module}::isinf($dt)");
        } elsif (defined $cd->{cl_value}) {
            $c->add_ccl($cd, "!$cd->{_sun_module}::isinf($dt)");
        }
    }
}

1;
# ABSTRACT: perl's type handler for type "float"

=for Pod::Coverage ^(compiler|clause_.+|handle_.+)$
