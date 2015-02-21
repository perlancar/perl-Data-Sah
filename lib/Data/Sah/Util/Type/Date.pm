package Data::Sah::Util::Type::Date;

# DATE
# VERSION

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Scalar::Util qw(blessed looks_like_number);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       coerce_date
               );

sub coerce_date {
    my $val = shift;
    if (!defined($val)) {
        return undef;
    } elsif (blessed($val) && $val->isa('DateTime')) {
        return $val;
    } elsif (looks_like_number($val) && $val >= 10**8 && $val <= 2**31) {
        require DateTime;
        return DateTime->from_epoch(epoch => $val);
    } elsif ($val =~ /\A([0-9]{4})-([0-9]{2})-([0-9]{2})\z/) {
        require DateTime;
        my $d;
        eval { $d = DateTime->new(year=>$1, month=>$2, day=>$3) };
        return undef if $@;
        return $d;
    } else {
        return undef;
    }
}

1;
# ABSTRACT: Utility related to date type

=head1 DESCRIPTION


=head1 FUNCTIONS

=head2 coerce_date($val) => DATETIME OBJ|undef

Coerce value to DateTime object according to perl Sah compiler (see
L<Data::Sah::Compiler::perl::TH::date>). Return undef if value is not
acceptable.

=cut
