package Data::Sah::Emitter::Perl::Type::DateTime;
# ABSTRACT: Perl-emitter for 'datetime' type

use Any::Moose;
extends 'Sah::Emitter::Perl::Type::Base';
with 'Sah::Spec::v10::Type::DateTime';

# XXX emit 'use DateTime;'

sub clause_PREPROCESS {
    # XXX convert string data of certain acceptable format to DateTime object
}

after clause_SANITY => sub {
    my ($self, %args) = @_;
    my $attr = $args{attr};
    my $e = $self->emitter;

    # XXX no need? already in PREPROCESS?
};

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
