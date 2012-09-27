package Data::Sah::Compiler::perl::TH::num;

use 5.010;
use Log::Any '$log';
use Moo;
extends 'Data::Sah::Compiler::perl::TH';
with 'Data::Sah::Type::num';

# VERSION

sub superclause_comparable {
    my ($self, $which, $cd) = @_;
}

sub superclause_sortable {
    my ($self, $which, $cd) = @_;
    my $crec  = $cd->{crec};
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

1;
# ABSTRACT: perl's type handler for type "num"
