package Data::Sah;

# split to delay loading Scalar::Util

use 5.010;
use strict;
use warnings;

use Scalar::Util qw(blessed);

our $type_re   = qr/\A[A-Za-z_]\w*(?:::[A-Za-z_]\w*)*\z/;
our $clause_re = qr/\A[A-Za-z_]\w*\z/;

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

        my $has_req = $s =~ s/\*\z//;
        $s =~ $type_re or die "Invalid type syntax $s, please use ".
            "letter/digit/underscore only";
        return [$s, $has_req ? {req=>1} : {}];

    } elsif ($ref eq 'ARRAY') {

        my $t = $s->[0];
        my $has_req = $t =~ s/\*\z//;
        if (!defined($t)) {
            die "For array form, at least 1 element is needed for type";
        } elsif (ref $t) {
            die "For array form, first element must be a string";
        } elsif (length(@$s) > 3) {
            die "For array form, there must be at most 3 elements";
        }
        $t =~ $type_re or die "Invalid type syntax $s, please use ".
            "letter/digit/underscore only";

        my $cset0;
        my $extras;
        if (defined($s->[1])) {
            if (ref($s->[1]) eq 'HASH') {
                $cset0 = $s->[1];
                $extras = $s->[2];
            } else {
                # flattened clause set [t, c=>1, c2=>2, ...]
                die "For array in the form of [t, c1=>1, ...], there must be ".
                    "3 elements (or 5, 7, ...)"
                        unless @$s % 2;
                $cset0 = { @{$s}[1..@$s-1] };
            }
        } else {
            $cset0 = {};
        }

        # check clauses and parse shortcuts (!c, c&, c|)
        my $cset = {};
        $cset->{req} = 1 if $has_req;
        for my $c (keys %$cset0) {
            my $v = $cset0->{$c};

            # ignore merge prefix
            my $mp = "";
            $c =~ s/\A(\[merge[!^+.*-]?\])// and $mp = $1;

            my $sc = "";
            if ($c =~ s/\A!(?=.)//) {
                $sc = "!";
            } elsif ($c =~ s/(?<=.)\|\z//) {
                $sc = "|";
            } elsif ($c =~ s/(?<=.)\&\z//) {
                $sc = "&";
            } elsif ($c !~ $clause_re) {
                die "Invalid clause name syntax '$c', please use ".
                    "letter/digit/underscore only";
            }

            # XXX currently shortcut conflict checking does not take merge
            # prefix into account
            if ($sc eq '!') {
                die "Conflict between clause shortcuts '!$c' and '$c'"
                    if exists $cset0->{$c};
                die "Conflict between clause shortcuts '!$c' and '$c|'"
                    if exists $cset0->{"$c|"};
                die "Conflict between clause shortcuts '!$c' and '$c&'"
                    if exists $cset0->{"$c&"};
                $cset->{$c} = $v;
                $cset->{"$c.max_ok"} = 0;
            } elsif ($sc eq '&') {
                die "Conflict between clause shortcuts '$c&' and '$c'"
                    if exists $cset0->{$c};
                die "Conflict between clause shortcuts '$c&' and '$c|'"
                    if exists $cset0->{"$c&"};
                die "Clause 'c&' value must be an array"
                    unless ref($v) eq 'ARRAY';
                $cset->{"$c.vals"} = $v;
                $cset->{"$c.max_nok"} = 0;
            } elsif ($sc eq '|') {
                die "Conflict between clause shortcuts '$c|' and '$c'"
                    if exists $cset0->{$c};
                die "Clause 'c|' value must be an array"
                    unless ref($v) eq 'ARRAY';
                $cset->{"$c.vals"} = $v;
                $cset->{"$c.min_ok"} = 1;
            } else {
                $cset->{$c} = $v;
            }

        }

        if (defined $extras) {
            die "For array form with 3 elements, extras must be hash"
                unless ref($extras) eq 'HASH';
            return [$t, $cset, $extras];
        } else {
            return [$t, $cset];
        }
    }

    die "Schema must be a string or arrayref (not $ref)";
}

1;
