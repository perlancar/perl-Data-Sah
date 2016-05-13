package Data::Sah::Compiler::perl::Coerce::date::int_epoch;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

use parent qw(Data::Sah::Compiler::perl::Coerce);

sub coerce {
    my $self = shift;
    my $cd = shift;
    my $dt = @_ ? shift : $cd->{args}{data_term};

    my $c = $cd->{compiler};

    my $coerce_cd = {};
    $coerce_cd->{expr_check} = join(
        " && ",
        "!ref($dt)",
        "$dt =~ /\\A[0-9]{8,10}\\z/",
        "$dt >= 10**8",
        "$dt <= 2**31",
    );

    my $coerce_to = $cd->{coerce_to};
    if ($coerce_to eq 'int(epoch)') {
        $coerce_cd->{expr_coerce} = $dt;
    } elsif ($coerce_to eq 'DateTime') {
        $c->add_module($cd, "DateTime");
        $coerce_cd->{expr_coerce} = "DateTime->from_epoch(epoch => $dt)";
    } elsif ($coerce_to eq 'Time::Moment') {
        $c->add_module($cd, "Time::Moment");
        $coerce_cd->{expr_coerce} = "Time::Moment->from_epoch($dt)";
    } else {
        die "BUG: Unknown coerce_to value '$cd->{coerce_to}'";
    }

    $coerce_cd;
}

1;
# ABSTRACT: Coerce date from integer (assumed to be epoch)

=for Pod::Coverage ^(should_coerce|coerce)$

=head1 DESCRIPTION

To avoid confusion with integer that contains "YYYY", "YYYYMM", or "YYYYMMDD",
we only do this coercion if data is an integer between 10^8 and 2^31.

Subclassed from L<Data::Sah::Compiler::perl::Coerce>.


=head1 METHODS

See parent documentation.
