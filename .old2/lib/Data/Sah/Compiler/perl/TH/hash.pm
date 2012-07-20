package Data::Sah::Compiler::perl::TH::hash;
# ABSTRACT: Perl type handler for type 'hash'

use Moo;
extends 'Data::Sah::Compiler::perl::TH::BaseperlTH';
with 'Data::Sah::Type::hash';

# VERSION

after clause_SANITY => sub {
    my ($self, %args) = @_;
    my $clause = $args{clause};
    my $e = $self->compiler;

    $e->errif($clause, 'ref($data) ne "HASH"', 'last ATTRS');
};

sub clause_all_elements {
}

sub clause_elements {
}

sub clause_element_deps {
}

sub clause_elements_regex {
}

sub clause_max_len {
}

sub clause_len {
}

sub clause_min_len {
}

sub clause_allow_extra_keys {
}

sub clause_codependent_keys {
}

sub clause_codependent_keys_regex {
}

sub clause_conflicting_keys {
}

sub clause_conflicting_keys_regex {
}

sub clause_ignore_keys {
}

sub clause_ignore_keys_regex {
}

sub clause_keys {
}

sub clause_keys_match {
}

sub clause_keys_not_match {
}

sub clause_keys_of {
}

sub clause_keys_one_of {
}

sub clause_keys_regex {
}

sub clause_required_keys {
}

sub clause_required_keys_regex {
}

sub clause_some_of {
}

sub clause_values_match {
}

sub clause_values_not_match {
}

sub clause_values_one_of {
}

sub clause_values_unique {
}

1;
