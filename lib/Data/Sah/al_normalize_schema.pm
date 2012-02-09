package Data::Sah;

# split to delay loading Scalar::Util

use 5.010;
use strict;
use warnings;

use Scalar::Util qw(blessed);

sub normalize_schema {
    my $self;
    if (blessed $_[0]) {
        $self = shift;
    } else {
        $self = __PACKAGE__->new;
    }
    my ($s) = @_;

    my $ref = ref($s);
    if (!defined($s)) {

        die "Schema is missing";

    } elsif (!$ref) {

        if ($s =~ s/\*\z//) {
            return [$s, {req=>1}];
        } else {
            return [$s, {}];
        }

    } elsif ($ref eq 'ARRAY') {

        if (!defined($s->[0])) {
            die "For array form, at least 1 element is needed for type";
        } elsif (ref($s->[0])) {
            die "For array form, first element must be a string";
        } elsif (length(@$s) > 3) {
            die "For array form, there must be at most 3 elements";
        }
        my $t = $s->[0];
        my $cset;

        if (defined($s->[1])) {
            # [t, c=>1, c2=>2, ...] => [t, {c=>1, c2=>2, ...}]
            if (ref($s->[1]) eq 'HASH') {
                $cset = { %{$s->[1]} };
            } else {
                die "For array in the form of [t, c1=>1, ...], there must be ".
                    "3 elements (or 5, 7, ...)"
                        unless @$s % 2;
                $cset = { @{$s}[1..@$s-1] };
            }
        } else {
            $cset = {};
        }

        if ($t =~ s/\*\z//) {
            $cset->{req} = 1;
        }

        return [$t, $cset];
    }

    die "Schema must be a string or arrayref (not $ref)";
}

1;
