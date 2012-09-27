package Data::Sah::Compiler::perl::TH::int;

use 5.010;
use Log::Any '$log';
use Moo;
extends 'Data::Sah::Compiler::perl::TH::num';
with 'Data::Sah::Type::int';

# VERSION

sub clause_div_by {}

sub clause_mod {
    my ($self, $cd) = @_;
    my $crec  = $cd->{clause};
    my $input = $cd->{input};
    my $dt    = $input->{data_term};
    my $com   = $self->compiler;

    my ($v1t, $v2t);
    if ($com->_v_is_expr($crec)) {
        my $vt = $com->_vterm($crec);
        $v1t = $vt . '->[0]';
        $v2t = $vt . '->[1]';
    } else {
        my $v = $crec->{val};
        $v1t = $com->_dump($v->[0]);
        $v2t = $com->_dump($v->[1]);
    }

    $cd->{result}{expr} //= [];
    push @{ $cd->{result}{expr} }, "$dt % $v1t == $v2t";
}

1;
# ABSTRACT: perl's type handler for type "int"

=cut
