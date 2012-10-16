package Data::Sah::Compiler::perl::TH::num;

use 5.010;
use Log::Any '$log';
use Moo;
extends 'Data::Sah::Compiler::perl::TH';
with 'Data::Sah::Type::num';

# VERSION

sub superclause_comparable {
    my ($self, $which, $cd) = @_;
    my $c = $self->compiler;

    $c->handle_clause(
        $cd,
        on_term => sub {
            my ($self, $cd) = @_;
            my $ct = $cd->{cl_term};
            my $dt = $cd->{data_term};

            if ($which eq 'is') {
                $c->add_ccl($cd, "$dt == $ct");
            } elsif ($which eq 'in') {
                $c->add_ccl($cd, "$dt ~~ $ct");
            }
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
                $c->add_ccl($cd, "$dt >= $ct\->[0] && $dt <= $ct\->[1]");
            } elsif ($which eq 'xbetween') {
                $c->add_ccl($cd, "$dt >= $ct\->[0] && $dt <= $ct\->[1]");
            }
        },
    );
}

1;
# ABSTRACT: perl's type handler for type "num"
