package Data::Sah::Compiler::perl::TH;

# DATE
# VERSION

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Mo qw(build default);
use Role::Tiny::With;

extends 'Data::Sah::Compiler::Prog::TH';

sub gen_each {
    my ($self, $which, $cd, $indices_expr, $elems_expr) = @_;
    my $c  = $self->compiler;
    my $cv = $cd->{cl_value};
    my $dt = $cd->{data_term};

    local $cd->{_subdata_level} = $cd->{_subdata_level} + 1;
    my $use_dpath = $cd->{args}{return_type} ne 'bool';

    $c->add_module($cd, 'List::Util');
    my %iargs = %{$cd->{args}};
    $iargs{outer_cd}             = $cd;
    $iargs{data_name}            = '_';
    $iargs{data_term}            = '$_';
    $iargs{schema}               = $cv;
    $iargs{schema_is_normalized} = 0;
    $iargs{indent_level}++;
    my $icd = $c->compile(%iargs);
    my @code = (
        "!defined(List::Util::first(sub {!(\n",
        ($c->indent_str($cd), "(\$_sahv_dpath->[-1] = defined(\$_sahv_dpath->[-1]) ? ".
             "\$_sahv_dpath->[-1]+1 : 0),\n") x !!$use_dpath,
        $icd->{result}, "\n",
        $c->indent_str($icd), ")}, ",
        $which eq 'each_index' ? $indices_expr : $elems_expr,
        "))",
    );
    $c->add_ccl($cd, join("", @code), {subdata=>1});
}

1;
# ABSTRACT: Base class for perl type handlers

=for Pod::Coverage ^(compiler|clause_.+|gen_.+)$
