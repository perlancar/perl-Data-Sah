package Data::Sah::Emitter::Human::Type::Base;
# ABSTRACT: Base class for Human type emitters

use Any::Moose;

has 'emitter' => (is => 'rw');

sub attr_SANITY {
}

sub attr_default {
}

sub after_attr {
}

sub attr_prefilters {
}

sub attr_postfilters {
}

sub attr_lang {
}

sub attr_required {
}

sub attr_forbidden {
}

sub attr_set {
}

sub attr_deps {
}

sub mattr_comparable {
}

sub mattr_sortable {
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
