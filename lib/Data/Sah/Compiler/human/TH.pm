package Data::Sah::Compiler::human::TH;

use Moo;
extends 'Data::Sah::Compiler::TH';

# VERSION

sub handle_type {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    # give the class name
    my $pkg = ref($self);
    $pkg =~ s/^Data::Sah::Compiler::human::TH:://;

    $c->add_ccl($cd, {type=>'noun', fmt=>$pkg});
}

# not translated

sub clause_name {}
sub clause_summary {}
sub clause_description {}
sub clause_comment {}
sub clause_tags {}

sub clause_prefilters {}
sub clause_postfilters {}

# ignored

sub clause_ok {}

# handled in after_all_clauses

sub clause_req {}
sub clause_forbidden {}

# default implementation

sub clause_default {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    $c->add_ccl($cd, {expr=>1,
                      fmt => 'default value %s'});
}

sub clause_clause {
    my ($self, $cd) = @_;

    my $cv = $cd->{cl_value};
    my $clause = $cv->[0];

    my $save = $self->{ccls_hash}{$clause};
    $self->SUPER::clause_clause($cd);
    $self->{ccls_hash}{"clause"} = $self->{ccls_hash}{$clause}
        if $cd->{args}{_create_ccls_hash};
    $self->{ccls_hash}{$clause} = $save;
}

1;
# ABSTRACT: Base class for human type handlers

=for Pod::Coverage ^(compiler|clause_.+|handle_.+)$

