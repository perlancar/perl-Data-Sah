package Data::Sah::Compiler::perl::TH::int;

# DATE
# VERSION

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Mo qw(build default);
use Role::Tiny::With;

extends 'Data::Sah::Compiler::perl::TH::num';
with 'Data::Sah::Type::int';

sub handle_type {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    my $dt = $cd->{data_term};
    if ($cd->{args}{core} || $cd->{args}{no_modules}) {
        $cd->{_ccl_check_type} = "$dt =~ ".'/\A[+-]?(?:0|[1-9][0-9]*)\z/';
    } else {
        $c->add_sun_module($cd);
        $cd->{_ccl_check_type} =
            "$cd->{_sun_module}::isint($dt)";
    }
}

sub clause_div_by {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    $c->add_ccl($cd, "$dt % $ct == 0");
}

sub clause_mod {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    $c->add_ccl($cd, "$dt % $ct\->[0] == $ct\->[1]");
}

1;
# ABSTRACT: perl's type handler for type "int"

=for Pod::Coverage ^(clause_.+|superclause_.+)$
