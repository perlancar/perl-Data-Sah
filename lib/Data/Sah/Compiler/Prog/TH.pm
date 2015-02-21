package Data::Sah::Compiler::Prog::TH;

# DATE
# VERSION

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Mo qw(build default);

extends 'Data::Sah::Compiler::TH';

# handled in compiler's before_all_clauses()

sub clause_default {}
sub clause_ok {}
sub clause_req {}
sub clause_forbidden {}
sub clause_prefilters {}

# handled in compiler's after_all_clauses()

#sub clause_postfilters {}

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

# temporarily use temporary variable for referring to data (e.g. when converting
# non-number to number for checking in clauses, or prefiltering)
sub set_tmp_data_term {
    my ($self, $cd, $expr) = @_;
    my $c = $self->compiler;
    #$log->errorf("TMP: set_tmp_data_term");

    my $tdn = $cd->{args}{tmp_data_name};
    my $tdt = $cd->{args}{tmp_data_term};
    my $t = $c->expr_array_subscript($tdt, $cd->{_subdata_level});
    unless ($cd->{_save_data_term}) {
        $c->add_var($cd, $tdn, []);
        $cd->{_save_data_term} = $cd->{data_term};
        $cd->{data_term} = $t;
    }
    local $cd->{_debug_ccl_note} = 'set temporary data term';
    $c->add_ccl($cd, "(".$c->expr_assign($t, $expr). ", ".$c->true.")");
}

sub restore_data_term {
    my ($self, $cd) = @_;
    my $c = $self->compiler;
    #$log->errorf("TMP: restore_data_term");

    my $tdt = $cd->{args}{tmp_data_term};
    if ($cd->{_save_data_term}) {
        $cd->{data_term} = delete($cd->{_save_data_term});
        local $cd->{_debug_ccl_note} = 'restore original data term';
        $c->add_ccl($cd, "(".$c->expr_pop($tdt). ", ".$c->true.")");
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

1;
# ABSTRACT: Base class for programming-language emiting compiler's type handlers

=for Pod::Coverage ^(compiler|clause_.+|handle_.+|gen_.+|set_tmp_data_term|restore_data_term)$

=cut
