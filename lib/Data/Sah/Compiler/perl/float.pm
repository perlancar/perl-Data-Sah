package Data::Sah::Compiler::perl::float;

use 5.010;
use Log::Any '$log';
use Moo;
extends 'Data::Sah::Compiler::perl::num';
with 'Data::Sah::Type::float';

# VERSION

my $LLN = "Scalar::Util::looks_like_number";

sub handle_type {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    my $dt = $cd->{data_term};
    $c->add_module($cd, 'Scalar::Util');
    $cd->{_ccl_check_type} = "$LLN($dt) =~ " .
        '/^(?:1|2|9|10|4352|4|5|6|12|13|14|20|28|36|44|8704)$/';
}

sub clause_is_nan {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    $c->handle_clause(
        $cd,
        on_term => sub {
            my ($self, $cd) = @_;
            my $ct = $cd->{cl_term};
            my $dt = $cd->{data_term};

            if ($cd->{cl_is_expr}) {
                $c->add_ccl(
                    $cd,
                    join(
                        "",
                        "$ct ? $LLN($dt) =~ /^(36|44)\$/ : ",
                        "defined($ct) ? $LLN($dt) !~ /^(36|44)\$/ : 1",
                    )
                );
            } else {
                if ($cd->{cl_value}) {
                    $c->add_ccl($cd, "$LLN($dt) =~ /^(36|44)\$/");
                } elsif (defined $cd->{cl_value}) {
                    $c->add_ccl($cd, "$LLN($dt) !~ /^(36|44)\$/");
                }
            }
        },
    );
}

sub clause_is_pos_inf {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    $c->handle_clause(
        $cd,
        on_term => sub {
            my ($self, $cd) = @_;
            my $ct = $cd->{cl_term};
            my $dt = $cd->{data_term};

            if ($cd->{cl_is_expr}) {
                $c->add_ccl($cd, "$ct ? $dt == 'inf' : ".
                                "defined($ct) ? $dt != 'inf' : 1");
            } else {
                if ($cd->{cl_value}) {
                    $c->add_ccl($cd, "$dt == 'inf'");
                } elsif (defined $cd->{cl_value}) {
                    $c->add_ccl($cd, "$dt != 'inf'");
                }
            }
        },
    );
}

sub clause_is_neg_inf {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    $c->handle_clause(
        $cd,
        on_term => sub {
            my ($self, $cd) = @_;
            my $ct = $cd->{cl_term};
            my $dt = $cd->{data_term};

            if ($cd->{cl_is_expr}) {
                $c->add_ccl($cd, "$ct ? $dt == '-inf' : ".
                                "defined($ct) ? $dt != '-inf' : 1");
            } else {
                if ($cd->{cl_value}) {
                    $c->add_ccl($cd, "$dt == '-inf'");
                } elsif (defined $cd->{cl_value}) {
                    $c->add_ccl($cd, "$dt != '-inf'");
                }
            }
        },
    );
}

sub clause_is_inf {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    $c->handle_clause(
        $cd,
        on_term => sub {
            my ($self, $cd) = @_;
            my $ct = $cd->{cl_term};
            my $dt = $cd->{data_term};

            if ($cd->{cl_is_expr}) {
                $c->add_ccl($cd, "$ct ? abs($dt) == 'inf' : ".
                                "defined($ct) ? abs($dt) != 'inf' : 1");
            } else {
                if ($cd->{cl_value}) {
                    $c->add_ccl($cd, "abs($dt) == 'inf'");
                } elsif (defined $cd->{cl_value}) {
                    $c->add_ccl($cd, "abs($dt) != 'inf'");
                }
            }
        },
    );
}

1;
# ABSTRACT: perl's type handler for type "float"

=cut
