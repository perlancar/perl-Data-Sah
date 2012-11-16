package Data::Sah::Compiler::human::TH::num;

use 5.010;
use Log::Any '$log';
use Moo;
extends 'Data::Sah::Compiler::human::TH';
with 'Data::Sah::Type::num';

# VERSION

sub handle_type {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    $c->add_ccl($cd, {noun => "number"});
}

sub superclause_comparable {
    my ($self, $which, $cd) = @_;
    my $c = $self->compiler;

    $c->handle_clause(
        $cd,
        on_term => sub {
            my ($self, $cd) = @_;
            my $ch = $cd->{cl_human};

            my $cl;
            if ($which eq 'is') {
                $cl = "be %s";
            } elsif ($which eq 'in') {
                $cl = "one of %s";
            }
            $c->add_ccl($cd, {clause=>$cl, params=>[$ch]});
        },
    );
}

sub superclause_sortable {
    my ($self, $which, $cd) = @_;
    my $c = $self->compiler;

    $c->handle_clause(
        $cd,
        on_term => sub {
            my ($self, $cd) = @_;
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
                    $c->add_ccl($cd, "$dt >= $ct\->[0] && $dt <= $ct\->[1]");
                } else {
                    # simplify code
                    $c->add_ccl($cd, "$dt >= $cv->[0] && $dt <= $cv->[1]");
                }
            } elsif ($which eq 'xbetween') {
                if ($cd->{cl_is_expr}) {
                    $c->add_ccl($cd, "$dt > $ct\->[0] && $dt < $ct\->[1]");
                } else {
                    # simplify code
                    $c->add_ccl($cd, "$dt > $cv->[0] && $dt < $cv->[1]");
                }
            }
        },
    );
}

1;
# ABSTRACT: perl's type handler for type "num"
