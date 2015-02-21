package Data::Sah::Compiler::js::TH::obj;

# DATE
# VERSION

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Mo qw(build default);
use Role::Tiny::With;

extends 'Data::Sah::Compiler::js::TH';
with 'Data::Sah::Type::obj';

sub handle_type {
    my ($self, $cd) = @_;
    my $c = $self->compiler;
    my $dt = $cd->{data_term};

    $cd->{_ccl_check_type} = "typeof($dt) == 'object'";
}

sub clause_can {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    $c->add_ccl($cd, "typeof($dt\[$ct])=='function'");
    # for property: ($dt).hasOwnProperty($ct)
}

sub clause_isa {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    $c->_die_unimplemented_clause($cd);
    # doesn't work? in nodejs?
    #$c->add_ccl($cd, "$dt instanceOf global($ct)");
}

1;
# ABSTRACT: js's type handler for type "obj"

=for Pod::Coverage ^(clause_.+|superclause_.+)$
