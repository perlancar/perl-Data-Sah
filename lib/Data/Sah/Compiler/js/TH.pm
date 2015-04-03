package Data::Sah::Compiler::js::TH;

# DATE
# VERSION

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Mo qw(build default);

extends 'Data::Sah::Compiler::Prog::TH';

sub gen_each {
    my ($self, $cd, $indices_expr, $data_name, $data_term, $code_at_sub_begin) = @_;
    my $c  = $self->compiler;
    my $cv = $cd->{cl_value};
    my $dt = $cd->{data_term};

    local $cd->{_subdata_level} = $cd->{_subdata_level} + 1;
    my $use_dpath = $cd->{args}{return_type} ne 'bool';

    my %iargs = %{$cd->{args}};
    $iargs{outer_cd}             = $cd;
    $iargs{data_name}            = $data_name,
    $iargs{data_term}            = $data_term,
    $iargs{schema}               = $cv;
    $iargs{schema_is_normalized} = 0;
    $iargs{indent_level}++;
    my $icd = $c->compile(%iargs);
    my @code = (
        "(", $indices_expr, ").every(function(_sahv_idx){", ($code_at_sub_begin // ''), " return(\n",
        # if ary == [], then set ary[0] = 0, else set ary[-1] = ary[-1]+1
        ($c->indent_str($cd), "(_sahv_dpath[_sahv_dpath.length ? _sahv_dpath.length-1 : 0] = _sahv_idx),\n") x !!$use_dpath,
        $icd->{result}, "\n",
        $c->indent_str($icd), ")})",
    );
    $c->add_ccl($cd, join("", @code), {subdata=>1});
}

1;
# ABSTRACT: Base class for js type handlers

=for Pod::Coverage ^(compiler|clause_.+|gen_.+)$
