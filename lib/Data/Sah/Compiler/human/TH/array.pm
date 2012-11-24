package Data::Sah::Compiler::human::TH::array;

use 5.010;
use Log::Any '$log';
use Moo;
extends 'Data::Sah::Compiler::human::TH';
with 'Data::Sah::Compiler::human::TH::Comparable';
with 'Data::Sah::Compiler::human::TH::HasElems';
with 'Data::Sah::Type::array';

# VERSION

sub handle_type {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    $c->add_ccl($cd, {
        fmt   => ["array", "arrays"],
        type  => 'noun',
    });
}

sub clause_each_elem {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $cv = $cd->{cl_value};

    my $icd = $c->compile(
        schema       => $cv,
        #indent_level => $cd->{indent_level}+1,
        (map { $_=>$cd->{args}{$_} } qw(lang locale mark_fallback format)),
    );

    # can we say 'array of INOUNS', e.g. 'array of integers'?
    if (@{$icd->{ccls}} == 1) {
        my $c0 = $icd->{ccls}[0];
        if ($c0->{type} eq 'noun' && ref($c0->{text}) eq 'ARRAY' &&
                @{$c0->{text}} > 1 && @{$cd->{ccls}} &&
                    $cd->{ccls}[0]{type} eq 'noun') {
            for (ref($cd->{ccls}[0]{text}) eq 'ARRAY' ?
                     @{$cd->{ccls}[0]{text}} : ($cd->{ccls}[0]{text})) {
                my $fmt = $c->_xlt($cd, '%s of %s');
                $_ = sprintf $fmt, $_, $c0->{text}[1];
            }
            return;
        }
    }

    # nope, we can't
    $c->add_ccl($cd, {
        type  => 'list',
        fmt   => 'each element %(modal_verb_be)s',
        items => [
            $icd->{ccls},
        ],
        vals  => [],
    });
}

sub clause_elems {}

1;
__END__
sub clause_elems {
    my ($self_th, $cd) = @_;
    my $c = $self_th->compiler;

    $c->handle_clause(
        $cd,
        on_term => sub {
            my ($self, $cd) = @_;
            my $cv = $cd->{cl_value};
            my $dt = $cd->{data_term};

            my $jccl;
            {
                local $cd->{ccls} = [];
                local $cd->{args}{return_type} = 'bool';

                my $cdef = $cd->{cset}{"elems.create_default"} // 1;
                delete $cd->{ucset}{"elems.create_default"};

                for my $i (0..@$cv-1) {
                    my $sch = $c->main->normalize_schema($cv->[$i]);
                    my $edt = "$dt\->[$i]";
                    my $icd = $c->compile(
                        data_name    => "$cd->{args}{data_name}_$i",
                        data_term    => $edt,
                        schema       => $sch,
                        indent_level => $cd->{indent_level}+1,
                        schema_is_normalized => 1,
                        (map { $_=>$cd->{args}{$_} } qw(debug debug_log)),
                    );
                    local $cd->{_debug_ccl_note} = "elem: $i";
                    if ($cdef && defined($sch->[1]{default})) {
                        $c->add_ccl($cd, $icd->{result});
                    } else {
                        $c->add_ccl($cd, "\@{$dt} < ".($i+1).
                                        " || ($icd->{result})");
                    }
                }
                $jccl = $c->join_ccls(
                    $cd, $cd->{ccls}, {err_msg => ''});
            }
            $c->add_ccl($cd, $jccl);
        },
    );
}

1;
# ABSTRACT: human's type handler for type "array"

=for Pod::Coverage ^(clause_.+|superclause_.+)$
