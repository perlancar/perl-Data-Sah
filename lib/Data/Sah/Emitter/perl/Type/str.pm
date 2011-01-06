package Data::Sah::Emitter::perl::Type::str;
# ABSTRACT: Perl emitter for str

use Any::Moose;
extends 'Data::Sah::Emitter::perl::Type::Base';
with 'Data::Sah::Type::str';

after clause_SANITY => sub {
    my ($self, %args) = @_;
    my $attr = $args{attr};
    my $e = $self->emitter;
    my $t = $e->data_term;

    {
        fs_expr => "!ref($t)",
    }
};

sub clause_all_elems {
}

sub clause_elemdeps {
}

sub clause_elements_regex {
}

sub clause_maxlen {
}

sub clause_len {
}

sub clause_minlen {
}

sub clause_match {
}

sub clause_not_match {
}

sub clause_match_all {
}

sub clause_match_any {
}

sub clause_match_none {
}

sub clause_isa_regex {
}

sub superclause_match {
}

sub superclause_has_elems {
}

sub superclause_has_elems {
}

no Any::Moose;
1;
