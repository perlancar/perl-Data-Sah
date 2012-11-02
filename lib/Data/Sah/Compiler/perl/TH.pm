package Data::Sah::Compiler::perl::TH;

use Moo;
extends 'Data::Sah::Compiler::Prog::TH';

# VERSION

# handled in compiler's before_all_clauses()

sub clause_default {}
sub clause_ok {}
sub clause_req {}
sub clause_forbidden {}
sub clause_prefilters {}

# handled in compiler's after_all_clauses()
#sub clause_postfilters {}

sub gen_each {
    my ($self, $which, $cd, $indices_expr, $elems_expr) = @_;
    my $c  = $self->compiler;
    my $cv = $cd->{cl_value};
    my $dt = $cd->{data_term};

    $c->add_module($cd, 'List::Util');
    my $icd = $c->compile(
        data_name    => '_',
        schema       => $cv,
        indent_level => $cd->{indent_level}+1,
        (map { $_=>$cd->{args}{$_} } qw(debug debug_log)),
    );
    my @code = (
        $c->indent_str($cd), "!defined(List::Util::first {!(\n",
        $icd->{result}, "\n",
        $c->indent_str($icd), ")} ",
        $which eq 'each_index' ? $indices_expr : $elems_expr,
        ")",
    );
    $c->add_ccl($cd, join("", @code));
}

sub gen_any_or_all_of {
    my ($self, $which, $cd) = @_;
    my $c  = $self->compiler;
    my $cv = $cd->{cl_value};
    my $dt = $cd->{data_term};

    my $jccl;
    {
        local $cd->{ccls} = [];
        local $cd->{args}{return_type} = 'bool';
        for my $i (0..@$cv-1) {
            my $sch = $cv->[$i];
            my $icd = $c->compile(
                data_name    => $cd->{args}{data_name},
                schema       => $sch,
                indent_level => $cd->{indent_level}+1,
                (map { $_=>$cd->{args}{$_} } qw(debug debug_log)),
            );
            $c->add_ccl($cd, $icd->{result});
        }
        if ($which eq 'all') {
            $jccl = $c->join_ccls(
                $cd, $cd->{ccls}, {err_msg => ''});
        } else {
            $jccl = $c->join_ccls(
                $cd, $cd->{ccls}, {err_msg => '', min_ok => 1});
        }
    }
    $c->add_ccl($cd, $jccl);
}

# tmp
sub _warn_unimplemented {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    $c->handle_clause(
        $cd,
        on_term => sub {
            my ($self, $cd) = @_;
            my $cv = $cd->{cl_value};
            my $ct = $cd->{cl_term};
            my $dt = $cd->{data_term};

            warn "NOTICE: clause '$cd->{clause}' for type '$cd->{type}' ".
                "is currently unimplemented\n";
        },
    );
}

1;
# ABSTRACT: Base class for perl type handlers
