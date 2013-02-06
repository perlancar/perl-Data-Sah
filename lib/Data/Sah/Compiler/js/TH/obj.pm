package Data::Sah::Compiler::js::TH::obj;

use 5.010;
use Log::Any '$log';
use Moo;
extends 'Data::Sah::Compiler::js::TH';
with 'Data::Sah::Type::obj';

# VERSION

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

    $c->add_ccl($cd, "$dt instanceOf global($ct)");
}

1;
# ABSTRACT: js's type handler for type "obj"

=for Pod::Coverage ^(clause_.+|superclause_.+)$
