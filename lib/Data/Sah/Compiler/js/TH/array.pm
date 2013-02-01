package Data::Sah::Compiler::js::TH::array;

use 5.010;
use Log::Any '$log';
use Moo;
extends 'Data::Sah::Compiler::js::TH';
with 'Data::Sah::Type::array';

# VERSION

sub handle_type {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    my $dt = $cd->{data_term};
    $cd->{_ccl_check_type} = "ref($dt) eq 'ARRAY'";
}

my $FRZ = "Storable::freeze";

sub superclause_comparable {
    my ($self, $which, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    # Storable is chosen because it's core and fast. ~~ is not very
    # specific.
    $c->add_module($cd, 'Storable');

    if ($which eq 'is') {
        $c->add_ccl($cd, "$FRZ($dt) eq $FRZ($ct)");
    } elsif ($which eq 'in') {
        $c->add_ccl($cd, "$FRZ($dt) ~~ [map {$FRZ(\$_)} \@{ $ct }]");
    }
}

sub superclause_has_elems {
    my ($self_th, $which, $cd) = @_;
    my $c  = $self_th->compiler;
    my $cv = $cd->{cl_value};
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    if ($which eq 'len') {
        $c->add_ccl($cd, "\@{$dt} == $ct");
    } elsif ($which eq 'min_len') {
        $c->add_ccl($cd, "\@{$dt} >= $ct");
    } elsif ($which eq 'max_len') {
        $c->add_ccl($cd, "\@{$dt} <= $ct");
    } elsif ($which eq 'len_between') {
        if ($cd->{cl_is_expr}) {
            $c->add_ccl(
                $cd, "\@{$dt} >= $ct\->[0] && \@{$dt} >= $ct\->[1]");
        } else {
            # simplify code
            $c->add_ccl(
                $cd, "\@{$dt} >= $cv->[0] && \@{$dt} <= $cv->[1]");
        }
        #} elsif ($which eq 'has') {
    } elsif ($which eq 'each_index' || $which eq 'each_elem') {
        $self_th->gen_each($which, $cd, "0..\@{$dt}-1", "\@{$dt}");
    #} elsif ($which eq 'check_each_index') {
    #} elsif ($which eq 'check_each_elem') {
    #} elsif ($which eq 'uniq') {
    #} elsif ($which eq 'exists') {
    }
}

sub clause_elems {
    my ($self_th, $cd) = @_;
    my $c  = $self_th->compiler;
    my $cv = $cd->{cl_value};
    my $dt = $cd->{data_term};

    my $use_dpath = $cd->{args}{return_type} ne 'bool';

    my $jccl;
    {
        local $cd->{ccls} = [];
        #local $cd->{args}{return_type} = 'bool';

        my $cdef = $cd->{clset}{"elems.create_default"} // 1;
        delete $cd->{uclset}{"elems.create_default"};

        for my $i (0..@$cv-1) {
            local $cd->{spath} = [@{$cd->{spath}}, $i];
            my $sch = $c->main->normalize_schema($cv->[$i]);
            my $edt = "$dt\->[$i]";
            my %iargs = %{$cd->{args}};
            $iargs{outer_cd}             = $cd;
            $iargs{data_name}            = "$cd->{args}{data_name}_$i";
            $iargs{data_term}            = $edt;
            $iargs{schema}               = $sch;
            $iargs{schema_is_normalized} = 1;
            $iargs{indent_level}++;
            my $icd = $c->compile(%iargs);
            my @code = (
                ($c->indent_str($cd), "(\$_sahv_dpath->[-1] = $i),\n") x !!$use_dpath,
                $icd->{result}, "\n",
            );
            my $ires = join("", @code);
            local $cd->{_debug_ccl_note} = "elem: $i";
            if ($cdef && defined($sch->[1]{default})) {
                $c->add_ccl($cd, $ires);
            } else {
                $c->add_ccl($cd, "\@{$dt} < ".($i+1)." || ($ires)");
            }
        }
        $jccl = $c->join_ccls(
            $cd, $cd->{ccls}, {err_msg => ''});
    }
    $c->add_ccl($cd, $jccl, {subdata=>1});
}

1;
# ABSTRACT: js's type handler for type "array"

=for Pod::Coverage ^(clause_.+|superclause_.+)$
