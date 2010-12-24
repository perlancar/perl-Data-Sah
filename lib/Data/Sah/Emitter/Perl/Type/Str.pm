package Data::Sah::Emitter::Perl::Type::Str;
# ABSTRACT: Perl-emitter for 'string' type

use Any::Moose;
extends 'Sah::Emitter::Perl::Type::Base';
with 'Sah::Spec::v10::Type::Str';

after attr_SANITY => sub {
    my ($self, %args) = @_;
    my $attr = $args{attr};
    my $e = $self->emitter;

    $e->errif($attr, 'ref($data)', 'last ATTRS');
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

sub attr_match_all {
}

sub attr_match_one {
}

sub attr_not_match {
}

sub attr_isa_regex {
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
