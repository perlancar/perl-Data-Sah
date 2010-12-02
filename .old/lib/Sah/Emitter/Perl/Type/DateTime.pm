package Data::Schema::Emitter::Perl::Type::DateTime;
# ABSTRACT: Perl-emitter for 'datetime' type

use Any::Moose;
extends 'Data::Schema::Emitter::Perl::Type::Base';
with 'Data::Schema::Spec::v10::Type::DateTime';

# XXX emit 'use DateTime;'

sub attr_PREPROCESS {
    # XXX convert string data of certain acceptable format to DateTime object
}

after attr_SANITY => sub {
    my ($self, %args) = @_;
    my $attr = $args{attr};
    my $e = $self->emitter;

    # XXX no need? already in PREPROCESS?
};

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
