package Data::Sah::Compiler::Prog::TH;

use Moo;
extends 'Data::Sah::Compiler::TH';

# VERSION

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

# temporarily use temporary variable for referring to data (e.g. when converting
# non-number to number for checking in clauses, or prefiltering)
sub set_tmp_data {
    my ($self, $cd, $expr) = @_;
    my $c = $self->compiler;

    my $tdt;
    unless ($cd->{_tmp_data_term}) {
        my $tdn = "tmp_$cd->{args}{data_name}";
        $tdt = $c->var_sigil . $tdn;
        $cd->{_tmp_data_term} = $tdt;
        $c->add_var($cd, $tdn);

        $cd->{_save_data_term} = $cd->{args}{data_term};
        $cd->{args}{data_term} = $tdt;
    }

    $c->add_ccl($cd, "(".$c->expr_assign($tdt, $expr).", ".$c->true.")");
}

sub restore_data {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    my $tdt = delete($cd->{_tmp_data_term});
    $cd->{args}{data_term} = delete($cd->{_save_data_term});
}

1;
# ABSTRACT: Base class for programming-language emiting compiler's type handlers

=for Pod::Coverage ^(compiler|clause_.+|handle_.+|set_tmp_data|restore_data)$

=cut
