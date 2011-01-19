package Data::Sah::Compiler::perl::TH::array;
# ABSTRACT: Perl type handler for type 'array'

use Any::Moose;
extends 'Data::Sah::Compiler::perl::TH::BaseperlTH';
with 'Data::Sah::Type::array';

after clause_SANITY => sub {
    my ($self, %args) = @_;
    my $clause = $args{clause};
    my $e = $self->compiler;

    $e->errif($clause, 'ref($data) ne "ARRAY"', 'last ATTRS');
};

sub clause_all_elements {
    my ($self, %args) = @_;
    my $clause = $args{clause};
    my $e = $self->compiler;

    my $subschema = $clause->{raw_value};
    my $subname = $e->subname($subschema);
    $e->_emit($subschema, 1);
    $e->line('for (@$data) {')->inc_indent;
    $e->line("my \$subres = $subname(\$_);");
    $e->errif($clause, '!$subres->{success}', 'last');
    $e->dec_indent->line('}');
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

sub clause_some_of {
}

sub clause_unique {
}

no Any::Moose;
1;
