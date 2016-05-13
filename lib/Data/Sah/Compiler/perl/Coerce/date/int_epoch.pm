package Data::Sah::Compiler::perl::Coerce::date::int_epoch;

# DATE
# VERSION

sub handle_coercion {
    my ($self, $cd) = @_;


}

1;
# ABSTRACT: Coerce date from integer (assumed to be epoch)

=head1 DESCRIPTION

To avoid confusion with integer that contains "YYYY", "YYYYMM", or "YYYYMMDD",
we only do this coercion if data is an integer between 10^8 and 2^31.
