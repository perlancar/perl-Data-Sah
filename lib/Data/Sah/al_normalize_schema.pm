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
    my ($schema) = @_;

    if (!defined($schema)) {

        die "Schema is missing";

    } elsif (!ref($schema)) {

        my $s = $self->parse_string_shortcuts($schema);
        if (!defined($s)) {
            die "Can't parse shortcuts in string '$schema'";
        } elsif (!ref($s)) {
            return { type=>$s, clause_sets=>[], def=>{} };
        } else {
            return { type=>$s->[0], clause_sets=>[$s->[1]], def=>{} };
        }

    } elsif (ref($schema) eq 'ARRAY') {

        if (!defined($schema->[0])) {
            die "For array form, at least 1 element is needed for type";
        } elsif (ref($schema->[0])) {
            die "For array form, first element must be a string";
        }

        if (defined($schema->[1])) {
            # [t, c=>1, c2=>2, ...] => [t, {c=>1, c2=>2, ...}]
            if (ref($schema->[1]) ne 'ARRAY') {
                die "For array in the form of [t, c1=>1, ...], there must be ".
                    "3 elements (or 5, 7, ...)"
                        unless @$schema % 2;
                splice @$schema, 1, @$schema-1, {@{$schema}[1..@$schema-1]};
            }
        }

        my $s = $self->parse_string_shortcuts($schema->[0]);
        my $t;
        my $cs0;
        if (!defined($s)) {
            die "Can't parse shortcuts in first element '$schema->[0]'";
        } elsif (!ref($s)) {
            $t = $s;
            $cs0 = {};
        } else {
            $t = $s->[0];
            $cs0 = $s->[1];
        }
        my @clause_sets;
        if (@$schema > 1) {
            for (1..@$schema-1) {
                if (ref($schema->[$_]) ne 'HASH') {
                    die "For array form, element [$_] must be a hashref ".
                        "(clause set)";
                }
                my $cs = $_ == 1 ? {%$cs0, %{$schema->[1]}} : $schema->[$_];
                push @clause_sets, $cs;
            }
        } else {
            push @clause_sets, $cs0 if keys(%$cs0);
        }
        return { type=>$t, clause_sets=>\@clause_sets, def=>{} };

    } elsif (ref($schema) eq 'HASH') {

        if (!defined($schema->{type})) {
            die "For hash form, 'type' required";
        }
        my $s = $self->parse_string_shortcuts($schema->{type});
        my $t;
        my $cs0;
        if (!defined($s)) {
            die "Can't parse shortcuts in 'type' value '$schema->{type}'";
        } elsif (!ref($s)) {
            $t = $s;
        } else {
            $t = $s->[0];
            $cs0 = $s->[1];
        }
        my @clause_sets;
        my $cs = $schema->{clause_sets};
        if (defined($cs)) {
            if (ref($cs) eq 'HASH') {
                # assume clause_sets => {...} to be clause_sets =>[{...}]
                $cs = [$cs];
            } elsif (ref($cs) ne 'ARRAY') {
                die "For hash form, 'clause_sets' value must be an arrayref";
            }
            for (0..@$cs-1) {
                if (ref($cs->[$_]) ne 'HASH') {
                    die "For hash form, 'clause_sets'->[$_] must be a hashref";
                }
                push @clause_sets, $cs->[$_];
            }
        }
        if ($cs0) {
            if (@clause_sets) {
                $clause_sets[0] = {%$cs0, %{$clause_sets[0]}};
            } else {
                push @clause_sets, $cs0;
            }
        }
        my $def = $schema->{def};
        if (defined($def)) {
            if (ref($def) ne 'HASH') {
                die "For hash form, 'def' must be a hashref";
            }
        }
        $def //= {};
        for (keys %$schema) {
            die "Unknown key in hash form: '$_'"
                unless /^(type|clause_sets|def)$/;
        }
        return { type=>$t, clause_sets=>\@clause_sets, def=>$def };

    }

    die "Schema must be a string, arrayref, or hashref";
}

1;
