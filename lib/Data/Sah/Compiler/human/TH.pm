package Data::Sah::Compiler::human::TH;

use Moo;
extends 'Data::Sah::Compiler::TH';

# VERSION

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

# handled in handle_type()

sub clause_req {}
sub clause_forbidden {}

# handled in after_all_clauses

sub clause_default {}

# default implementation

sub handle_type {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    # give the class name
    my $pkg = ref($self);
    $pkg =~ s/^Data::Sah::Compiler::human::TH:://;

    $c->add_ccl($cd, {noun => $pkg});
}

1;
# ABSTRACT: Base class for human type handlers
