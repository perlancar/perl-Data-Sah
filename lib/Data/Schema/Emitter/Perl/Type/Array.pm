package Data::Schema::Emitter::Perl::Type::Array;
# ABSTRACT: Perl-emitter for 'array' type

use Any::Moose;
extends 'Data::Schema::Emitter::Perl::Type::Base';
with 'Data::Schema::Spec::v10::Type::Array';

after attr_SANITY => sub {
    my ($self, %args) = @_;
    my $attr = $args{attr};
    my $e = $self->emitter;

    $e->errif($attr, 'ref($data) ne "ARRAY"', 'last ATTRS');
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

sub attr_some_of {
}

sub attr_unique {
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
