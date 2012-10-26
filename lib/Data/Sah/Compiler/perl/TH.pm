package Data::Sah::Compiler::perl::TH;

use Moo;
extends 'Data::Sah::Compiler::BaseProg::TH';

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

1;
# ABSTRACT: Base class for perl type handlers
