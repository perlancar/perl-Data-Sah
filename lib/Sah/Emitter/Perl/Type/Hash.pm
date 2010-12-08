package Sah::Emitter::Perl::Type::Hash;
# ABSTRACT: Perl-emitter for 'hash' type

use Any::Moose;
extends 'Sah::Emitter::Perl::Type::Base';
with 'Sah::Spec::v10::Type::Hash';

after attr_SANITY => sub {
    my ($self, %args) = @_;
    my $attr = $args{attr};
    my $e = $self->emitter;

    $e->errif($attr, 'ref($data) ne "HASH"', 'last ATTRS');
};

sub attr_all_elements {
}

sub attr_elements {
}

sub attr_element_deps {
}

sub attr_elements_regex {
}

sub attr_max_len {
}

sub attr_len {
}

sub attr_min_len {
}

sub attr_allow_extra_keys {
}

sub attr_codependent_keys {
}

sub attr_codependent_keys_regex {
}

sub attr_conflicting_keys {
}

sub attr_conflicting_keys_regex {
}

sub attr_ignore_keys {
}

sub attr_ignore_keys_regex {
}

sub attr_keys {
}

sub attr_keys_match {
}

sub attr_keys_not_match {
}

sub attr_keys_of {
}

sub attr_keys_one_of {
}

sub attr_keys_regex {
}

sub attr_required_keys {
}

sub attr_required_keys_regex {
}

sub attr_some_of {
}

sub attr_values_match {
}

sub attr_values_not_match {
}

sub attr_values_one_of {
}

sub attr_values_unique {
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
