package Data::Sah::Emitter::Perl::Type::Hash;
# ABSTRACT: Perl-emitter for 'hash' type

use Any::Moose;
extends 'Sah::Emitter::Perl::Type::Base';
with 'Sah::Spec::v10::Type::Hash';

after clause_SANITY => sub {
    my ($self, %args) = @_;
    my $attr = $args{attr};
    my $e = $self->emitter;

    $e->errif($attr, 'ref($data) ne "HASH"', 'last ATTRS');
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

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
