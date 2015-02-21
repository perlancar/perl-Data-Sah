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
    my ($self, $which, $cd, $indices_expr, $elems_expr) = @_;
    my $c  = $self->compiler;
    my $cv = $cd->{cl_value};
    my $dt = $cd->{data_term};

    local $cd->{_subdata_level} = $cd->{_subdata_level} + 1;
    my $use_dpath = $cd->{args}{return_type} ne 'bool';

    my %iargs = %{$cd->{args}};
    $iargs{outer_cd}             = $cd;
    $iargs{data_name}            = '_sahv_x';
    $iargs{data_term}            = '_sahv_x';
    $iargs{schema}               = $cv;
    $iargs{schema_is_normalized} = 0;
    $iargs{indent_level}++;
    my $icd = $c->compile(%iargs);
    my @code = (
        "(", ($which eq 'each_index' ? $indices_expr : $elems_expr), ").every(function(_sahv_x){ return(\n",
        # if ary == [], then set ary[0] = 0, else set ary[-1] = ary[-1]+1
        ($c->indent_str($cd), "(_sahv_dpath[_sahv_dpath.length ? _sahv_dpath.length-1 : 0] = (_sahv_dpath[_sahv_dpath.length-1]===undefined || _sahv_dpath[_sahv_dpath.length-1]===null) ? 0 : _sahv_dpath[_sahv_dpath.length-1]+1),\n") x !!$use_dpath,
        $icd->{result}, "\n",
        $c->indent_str($icd), ")})",
    );
    $c->add_ccl($cd, join("", @code), {subdata=>1});
}

1;
# ABSTRACT: Base class for js type handlers

=for Pod::Coverage ^(compiler|clause_.+|gen_.+)$
