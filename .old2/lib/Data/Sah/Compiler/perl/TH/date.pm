package Data::Sah::Compiler::perl::TH::datetime;
# ABSTRACT: Perl type handler for type 'date'

use Moo;
##extends 'Data::Sah::Compiler::Perl::TH::BaseperlTH';
##with 'Data::Sah::Type::datetime';

# VERSION

# XXX emit 'use DateTime;'

sub clause_PREPROCESS {
    # XXX convert string data of certain acceptable format to DateTime object
}

after clause_SANITY => sub {
    my ($self, %args) = @_;
    my $clause = $args{clause};
    my $e = $self->compiler;

    # XXX no need? already in PREPROCESS?
};

1;
