package Data::Sah::Compiler::perl::Coerce::date::obj_DateTime;

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

    $c->add_module($cd, "Scalar::Util");

    my $coerce_cd = {};
    $coerce_cd->{expr_match} = join(
        " && ",
        "Scalar::Util::blessed($dt)",
        "$dt\->isa('DateTime')",
    );

    my $coerce_to = $cd->{coerce_to};
    if ($coerce_to eq 'int(epoch)') {
        $coerce_cd->{expr_coerce} = "$dt\->epoch";
    } elsif ($coerce_to eq 'DateTime') {
        $coerce_cd->{expr_coerce} = $dt;
    } elsif ($coerce_to eq 'Time::Moment') {
        $c->add_module($cd, "Time::Moment");
        $coerce_cd->{expr_coerce} = "Time::Moment->from_object($dt)";
    } else {
        die "BUG: Unknown coerce_to value '$cd->{coerce_to}'";
    }

    $coerce_cd;
}

1;
# ABSTRACT: Coerce date from DateTime object

=for Pod::Coverage ^(should_coerce|coerce)$

=head1 DESCRIPTION


=head1 METHODS

See parent documentation.
