package Data::Sah::Compiler::Human::TH::Base;
# ABSTRACT: Base class for Human type emitters

use Any::Moose;

has 'emitter' => (is => 'rw');

sub clause_SANITY {
}

sub clause_default {
}

sub after_clause {
}

sub clause_prefilters {
}

sub clause_postfilters {
}

sub clause_lang {
}

sub clause_required {
}

sub clause_forbidden {
}

sub clause_set {
}

sub clause_deps {
}

sub superclause_comparable {
}

sub superclause_sortable {
}

no Any::Moose;
1;
