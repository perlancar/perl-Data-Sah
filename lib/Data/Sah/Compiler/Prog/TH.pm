package Data::Sah::Compiler::Prog::TH;

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Mo qw(build default);

extends 'Data::Sah::Compiler::TH';

# AUTHORITY
# DATE
# DIST
# VERSION

# handled in compiler's before_all_clauses()

sub clause_default {}
sub clause_ok {}
sub clause_req {}
sub clause_forbidden {}
sub clause_prefilters {}

# handled in compiler's after_all_clauses()

sub clause_postfilters {}

sub clause_name {
    my ($self, $cd) = @_;
    $self->compiler->_ignore_clause_and_attrs($cd);
}

sub clause_summary {
    my ($self, $cd) = @_;
    $self->compiler->_ignore_clause_and_attrs($cd);
}

sub clause_description {
    my ($self, $cd) = @_;
    $self->compiler->_ignore_clause_and_attrs($cd);
}

sub clause_comment {
    my ($self, $cd) = @_;
    $self->compiler->_ignore_clause($cd);
}

sub clause_tags {
    my ($self, $cd) = @_;
    $self->compiler->_ignore_clause($cd);
}

sub clause_defhash_v {
    my ($self, $cd) = @_;
    $self->compiler->_ignore_clause($cd);
}

sub clause_v {
    my ($self, $cd) = @_;
    $self->compiler->_ignore_clause($cd);
}

sub clause_examples {
    my ($self, $cd) = @_;
    $self->compiler->_ignore_clause($cd);
}

sub clause_links {
    my ($self, $cd) = @_;
    $self->compiler->_ignore_clause($cd);
}

# temporarily use temporary variable for referring to data (e.g. when converting
# non-number to number for checking in clauses, or prefiltering)
sub set_tmp_data_term {
    my ($self, $cd, $expr) = @_;
    my $c = $self->compiler;
    #$log->errorf("TMP: set_tmp_data_term");

    $expr //= $cd->{data_term};

    my $tdn = $cd->{args}{tmp_data_name};
    my $tdt = $cd->{args}{tmp_data_term};
    my $t = $c->expr_array_subscript($tdt, $cd->{_subdata_level});
    unless ($cd->{_save_data_term}) {
        $c->add_var($cd, $tdn, []);
        $cd->{_save_data_term} = $cd->{data_term};
        $cd->{data_term} = $t;
    }
    local $cd->{_debug_ccl_note} = 'set temporary data term';
    $c->add_ccl($cd, "(".$c->expr_set($t, $expr). ", ".$c->true.")",
                {err_msg => ''});
}

sub restore_data_term {
    my ($self, $cd) = @_;
    my $c = $self->compiler;
    #$log->errorf("TMP: restore_data_term");

    my $tdt = $cd->{args}{tmp_data_term};
    if ($cd->{_save_data_term}) {
        $cd->{data_term} = delete($cd->{_save_data_term});
        local $cd->{_debug_ccl_note} = 'restore original data term';
        $c->add_ccl($cd, "(".$c->expr_pop($tdt). ", ".$c->true.")",
                    {err_msg => ''});
    }
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
            local $cd->{spath} = [@{ $cd->{spath} }, $i];
            my $sch  = $cv->[$i];
            my %iargs = %{$cd->{args}};
            $iargs{outer_cd}             = $cd;
            $iargs{schema}               = $sch;
            $iargs{schema_is_normalized} = 0;
            $iargs{cache}                = $cd->{args}{cache};
            $iargs{indent_level}++;
            my $icd  = $c->compile(%iargs);
            my @code = (
                $icd->{result},
            );
            $c->add_ccl($cd, join("", @code));
        }
        if ($which eq 'all') {
            $jccl = $c->join_ccls(
                $cd, $cd->{ccls}, {err_msg=>''});
        } else {
            $jccl = $c->join_ccls(
                $cd, $cd->{ccls}, {err_msg=>'', op=>'or'});
        }
    }
    $c->add_ccl($cd, $jccl);
}

sub clause_if {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $cv = $cd->{cl_value};

    my ($cond, $then, $else) = @$cv;

    unless (!ref($cond) && ref($then) eq 'ARRAY' && !$else) {
        $c->_die($cd, "Sorry, for 'if' clause, I currently can only handle COND=str (expr), THEN=array (schema), and no ELSE");
    }

    # COND
    my $comp_cond = $c->expr($cd, $cond);

    # THEN
    my $comp_then;
    {
        local $cd->{ccls} = [];
        local $cd->{spath} = [@{ $cd->{spath} }, 'if'];
        my $sch  = $then;
        my %iargs = %{$cd->{args}};
        $iargs{outer_cd}             = $cd;
        $iargs{schema}               = $sch;
        $iargs{schema_is_normalized} = 0;
        $iargs{cache}                = $cd->{args}{cache};
        $iargs{indent_level}++;
        my $icd  = $c->compile(%iargs);
        my @code = (
            $icd->{result},
        );
        $comp_then = join("", @code);
    }

    $c->add_ccl(
        $cd,
        $c->expr_ternary($comp_cond, $comp_then, $c->true, {err_msg=>''}),
    );
}

1;
# ABSTRACT: Base class for programming-language emiting compiler's type handlers

=for Pod::Coverage ^(compiler|clause_.+|handle_.+|gen_.+|set_tmp_data_term|restore_data_term)$

=cut
