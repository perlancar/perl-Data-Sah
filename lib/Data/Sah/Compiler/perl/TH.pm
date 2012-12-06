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
    my %iargs = %{$cd->{args}};
    $iargs{outer_cd}             = $cd;
    $iargs{return_type}          = 'bool';
    $iargs{data_name}            = '_';
    $iargs{data_term}            = '$_';
    $iargs{schema}               = $cv;
    $iargs{schema_is_normalized} = 0;
    $iargs{indent_level}++;
    my $icd = $c->compile(%iargs);
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
        for my $i (0..@$cv-1) {
            local $cd->{path} = [@{ $cd->{path} }, $i];
            my $sch  = $cv->[$i];
            my %iargs = %{$cd->{args}};
            $iargs{outer_cd}             = $cd;
            $iargs{return_type}          = 'bool';
            $iargs{schema}               = $sch;
            $iargs{schema_is_normalized} = 0;
            $iargs{indent_level}++;
            my $icd  = $c->compile(%iargs);
            $c->add_ccl($cd, $icd->{result});
        }
        if ($which eq 'all') {
            $jccl = $c->join_ccls(
                $cd, $cd->{ccls}, {err_msg => ''});
        } else {
            $jccl = $c->join_ccls(
                $cd, $cd->{ccls}, {err_msg => '', op => 'or'});
        }
    }
    $c->add_ccl($cd, $jccl);
}

# tmp
sub _warn_unimplemented {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    warn "NOTICE: clause '$cd->{clause}' for type '$cd->{type}' ".
        "is currently unimplemented\n";
}

1;
# ABSTRACT: Base class for perl type handlers

=for Pod::Coverage ^(compiler|clause_.+|gen_.+)$

