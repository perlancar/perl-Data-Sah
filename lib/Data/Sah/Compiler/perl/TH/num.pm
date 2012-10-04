package Data::Sah::Compiler::perl::TH::num;

use 5.010;
use Log::Any '$log';
use Moo;
extends 'Data::Sah::Compiler::perl::TH';
with 'Data::Sah::Type::num';

# VERSION

sub superclause_comparable {
    my ($self, $which, $cd) = @_;
    my $c              = $self->compiler;
    my $cset           = $cd->{cset};
    my $cl             = $cd->{clause};
    my $cv             = $cset->{$cl};
    my $vt = $cset->{"$cl.is_expr"} ? $c->expr($cv) : $c->literal($cv);

    # XXX handle multi

    my $input = $cd->{input};
    my $it    = $input->{term};
    my $ee    = $cd->{exprs};

    if ($which eq 'is') {
        push @$ee, "($it == $vt)";
    } elsif ($which eq 'in') {
        push @$ee, "($it ~~ $vt)";
    }
}

sub superclause_sortable {}
# sub superclause_sortable {
#     my ($self, $which, $cd) = @_;
#     my $c     = $self->compiler;
#     my $cl    = $cd->{clause};
#     my $input = $cd->{input};
#     my $t     = $input->{term};

#     $cd->{result}{expr} //= [];

#     if ($which =~ /\Ax?(min|max)\z/) {
#         my $vt = $com->_vterm($crec);
#         my $op =
#             $which eq 'min' ? '>=' :
#                 $which eq 'xmin' ? '>' :
#                     $which eq 'max' ? '<=' : '<';
#         push @{ $cd->{result}{expr} }, "$dt $op $vt";
#     } elsif ($which =~ /\Ax?between\z/) {
#         my ($v1t, $v2t);
#         if ($com->_v_is_expr($crec)) {
#             my $vt = $com->_vterm($crec);
#             $v1t = $vt . '->[0]';
#             $v2t = $vt . '->[1]';
#         } else {
#             my $v = $crec->{val};
#             $v1t = $com->_dump($v->[0]);
#             $v2t = $com->_dump($v->[1]);
#         }
#         my $op1 = $which eq 'between' ? '<=' : '<';
#         my $op2 = $which eq 'between' ? '>=' : '>';
#         push @{ $cd->{result}{expr} }, "$dt $op1 $v1t && $dt $op2 $v2t";
#     } else {
#         die "BUG: Unknown sortable clause '$which'";
#     }
# }

1;
# ABSTRACT: perl's type handler for type "num"
