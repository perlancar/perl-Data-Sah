package Data::Sah::Compiler::perl::TH::int;

use 5.010;
use Log::Any '$log';
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
sub clause_div_by {}

# handle val / vals, {min,max}_{ok,nok}
sub xx {
}

sub superclause_sortable {
    my ($self, $which, $cd) = @_;
    my $crec  = $cd->{clause};
    my $input = $cd->{input};
    my $dt    = $input->{data_term};
    my $com   = $self->compiler;

    $cd->{result}{expr} //= [];

    if ($which =~ /\Ax?(min|max)\z/) {
        my $vt = $com->_vterm($crec);
        my $op =
            $which eq 'min' ? '>=' :
                $which eq 'xmin' ? '>' :
                    $which eq 'max' ? '<=' : '<';
        push @{ $cd->{result}{expr} }, "$dt $op $vt";
    } elsif ($which =~ /\Ax?between\z/) {
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
        my $op1 = $which eq 'between' ? '<=' : '<';
        my $op2 = $which eq 'between' ? '>=' : '>';
        push @{ $cd->{result}{expr} }, "$dt $op1 $v1t && $dt $op2 $v2t";
    } else {
        die "BUG: Unknown sortable clause '$which'";
    }
}

# XXX core clause handler should just be given data term, value term (and value,
# if value is not expr), and clause name (and produce exprs or statements [if
# exprs are not possible or statements wanted]), and error message?. a
# higher-level routine should determine what the data & value terms should be
# (handle literal vs expression, temporary variable assignment, vals / vals= /
# max_ok / min_ok / max_nok / min_nok ...).

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
