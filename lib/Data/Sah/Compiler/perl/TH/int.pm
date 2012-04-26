package Data::Sah::Compiler::perl::TH::int;

use 5.010;
use Moo;
extends 'Data::Sah::Compiler::perl::TH';
with 'Data::Sah::Type::int';

sub clause_default {}
sub clause_min_ok {}
sub clause_max_ok {}
sub clause_min_nok {}
sub clause_max_nok {}
sub clause_req {}
sub clause_forbidden {}
sub clause_PREPROCESS {}
sub clause_POSTPROCESS {}
sub clause_SANITY {}
sub superclause_comparable {}
sub clause_noop {}
sub clause_fail {}
sub clause_mod {}
sub clause_div_by {}

# handle val / vals, {min,max}_{ok,nok}
sub xx {
}

sub superclause_sortable {
    my ($self, $which, $cd) = @_;
    my $c     = $cd->{clause};
    my $input = $cd->{input};
    my $dt    = $input->{data_term};
    my $val   = defined($c->{"val="}) ? $c->{"val="} : # XXX compile expression
        $self->compiler->_dump($c->{val});

    $cd->{result}{expr} //= [];

    if ($which eq 'min') {
        push @{ $cd->{result}{expr} }, "$dt >= $val";
    } else {
        die "not yet implemented";
    }
}

1;
# ABSTRACT: perl's type handler for type "int"

=cut
