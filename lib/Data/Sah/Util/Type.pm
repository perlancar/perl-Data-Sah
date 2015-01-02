package Data::Sah::Util::Type;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(get_type is_simple is_numeric is_collection is_ref);

# XXX absorb and use metadata from Data::Sah::Type::*
my $type_metas = {
    all   => {scalar=>0, numeric=>0, ref=>0},
    any   => {scalar=>0, numeric=>0, ref=>0},
    array => {scalar=>0, numeric=>0, ref=>1},
    bool  => {scalar=>1, numeric=>0, ref=>0},
    buf   => {scalar=>1, numeric=>0, ref=>0},
    cistr => {scalar=>1, numeric=>0, ref=>0},
    code  => {scalar=>1, numeric=>0, ref=>1},
    float => {scalar=>1, numeric=>1, ref=>0},
    hash  => {scalar=>0, numeric=>0, ref=>1},
    int   => {scalar=>1, numeric=>1, ref=>0},
    num   => {scalar=>1, numeric=>1, ref=>0},
    obj   => {scalar=>1, numeric=>0, ref=>1},
    re    => {scalar=>1, numeric=>0, ref=>1, simple=>1},
    str   => {scalar=>1, numeric=>0, ref=>0},
    undef => {scalar=>1, numeric=>0, ref=>0},
};

sub get_type {
    my $sch = shift;

    if (ref($sch) eq 'ARRAY') {
        $sch = $sch->[0];
    }

    if (defined($sch) && !ref($sch)) {
        $sch =~ s/\*\z//;
        return $sch;
    } else {
        return undef;
    }
}

sub _normalize {
    require Data::Sah::Normalize;

    my ($sch, $opts) = @_;
    return $sch if $opts->{schema_is_normalized};
    return Data::Sah::Normalize::normalize_schema($sch);
}

# for any|all to pass a criteria, we assume that all of the schemas in the 'of'
# clause must also pass (and there must not be '!of', 'of&', or that kind of
# thing.
sub _handle_any_all {
    my ($sch, $opts, $crit) = @_;
    $sch = _normalize($sch, $opts);
    return 0 if $sch->[1]{'of.op'};
    my $of = $sch->[1]{of};
    return 0 unless $of && ref($of) eq 'ARRAY' && @$of;
    for (@$of) {
        return 0 unless $crit->($_);
    }
    1;
}

sub is_simple {
    my ($sch, $opts) = @_;
    $opts //= {};

    my $type = get_type($sch) or return undef;
    my $tmeta = $type_metas->{$type} or return undef;
    if ($type eq 'any' || $type eq 'all') {
        return _handle_any_all($sch, $opts, sub { is_simple(shift) });
    }
    return $tmeta->{simple} // ($tmeta->{scalar} && !$tmeta->{ref});
}

sub is_collection {
    my ($sch, $opts) = @_;
    $opts //= {};

    my $type = get_type($sch) or return undef;
    my $tmeta = $type_metas->{$type} or return undef;
    if ($type eq 'any' || $type eq 'all') {
        return _handle_any_all($sch, $opts, sub { is_collection(shift) });
    }
    return !$tmeta->{scalar};
}

sub is_numeric {
    my ($sch, $opts) = @_;
    $opts //= {};

    my $type = get_type($sch) or return undef;
    my $tmeta = $type_metas->{$type} or return undef;
    if ($type eq 'any' || $type eq 'all') {
        return _handle_any_all($sch, $opts, sub { is_numeric(shift) });
    }
    return $tmeta->{numeric};
}

sub is_ref {
    my ($sch, $opts) = @_;
    $opts //= {};

    my $type = get_type($sch) or return undef;
    my $tmeta = $type_metas->{$type} or return undef;
    if ($type eq 'any' || $type eq 'all') {
        return _handle_any_all($sch, $opts, sub { is_ref(shift) });
    }
    return $tmeta->{ref};
}

1;
# ABSTRACT: Utility functions related to types

=head1 SYNOPSIS

 use Data::Sah::Util::Type qw(
     get_type
     is_simple is_numeric is_collection is_ref
 );

 say get_type("int");                          # -> int
 say get_type("int*");                         # -> int
 say get_type([int => min=>0]);                # -> int

 say is_simple("int");                          # -> 1
 say is_simple("array");                        # -> 0
 say is_simple([any => of => ["float", "str"]); # -> 1

 say is_numeric(["int", min=>0]); # -> 1

 say is_collection("array*"); # -> 1

 say is_ref("code*"); # -> 1


=head1 DESCRIPTION

This module provides some secondary utility functions related to L<Sah> and
L<Data::Sah>. It is deliberately distributed separately from the Data-Sah main
distribution to be differentiated from Data::Sah::Util which contains "primary"
utilities and is distributed with Data-Sah.


=head1 FUNCTIONS

None exported by default, but they are exportable.

=head2 get_type($sch) => STR

=head2 is_simple($sch[, \%opts]) => BOOL

Simple means scalar and not a reference.

Options:

=over

=item * schema_is_normalized => BOOL

=back

=head2 is_collection($sch[, \%opts]) => BOOL

=head2 is_numeric($sch[, \%opts]) => BOOL

Currently, only C<num>, C<int>, and C<float> are numeric.

=head2 is_ref($sch[, \%opts]) => BOOL


=head1 SEE ALSO

L<Data::Sah>

=cut
