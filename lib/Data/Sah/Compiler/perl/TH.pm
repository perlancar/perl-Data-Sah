package Data::Sah::Compiler::perl::TH;

# AUTHORITY
# DATE
# DIST
# VERSION

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Mo qw(build default);
use Role::Tiny::With;

extends 'Data::Sah::Compiler::Prog::TH';

sub gen_each {
    my ($self, $cd, $indices_expr, $data_name, $data_term, $code_at_sub_begin) = @_;
    my $c  = $self->compiler;
    my $cv = $cd->{cl_value};
    my $dt = $cd->{data_term};

    local $cd->{_subdata_level} = $cd->{_subdata_level} + 1;

    $c->add_runtime_module($cd, 'List::Util');
    my %iargs = %{$cd->{args}};
    $iargs{outer_cd}             = $cd;
    $iargs{data_name}            = $data_name;
    $iargs{data_term}            = $data_term;
    $iargs{schema}               = $cv;
    $iargs{schema_is_normalized} = 0;
    $iargs{indent_level}++;
    $iargs{data_term_includes_topic_var} = 1;
    my $icd = $c->compile(%iargs);
    my @code = (
        "!defined(List::Util::first(sub {", ($code_at_sub_begin // ''), "!(\n",
        ($c->indent_str($cd),
         "(\$_sahv_dpath->[-1] = \$_),\n") x !!$cd->{use_dpath},
         $icd->{result}, "\n",
         $c->indent_str($icd), ")}, ",
         $indices_expr,
         "))",
    );
    $c->add_ccl($cd, join("", @code), {subdata=>1});
}

1;
# ABSTRACT: Base class for perl type handlers

=for Pod::Coverage ^(compiler|clause_.+|gen_.+)$
