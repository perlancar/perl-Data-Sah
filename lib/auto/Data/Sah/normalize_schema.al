package Data::Sah;

use 5.010;

sub normalize_schema {
    my ($self, $schema) = @_;

    if (!defined($schema)) {

        return "schema is missing";

    } elsif (!ref($schema)) {

        my $s = $self->parse_string_shortcuts($schema);
        if (!defined($s)) {
            return "can't understand type name / parse shortcuts in string `$schema`";
        } elsif (!ref($s)) {
            return { type=>$s, clause_sets=>[], def=>{} };
        } else {
            return { type=>$s->[0], clause_sets=>[$s->[1]], def=>{} };
        }

    } elsif (ref($schema) eq 'ARRAY') {

        if (!defined($schema->[0])) {
            return "array form needs at least 1 element for type";
        } elsif (ref($schema->[0])) {
            return "array form's first element must be a string";
        }
        my $s = $self->parse_string_shortcuts($schema->[0]);
        my $t;
        my $cs0;
        if (!defined($s)) {
            return "can't understand type name / parse shortcuts in first element `$schema->[0]`";
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
                    return "array form element [$_] (clause set) must be a hashref";
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
            return "hash form must have 'type' key";
        }
        my $s = $self->parse_string_shortcuts($schema->{type});
        my $t;
        my $cs0;
        if (!defined($s)) {
            return "can't understand type name / parse shortcuts in 'type' value `$schema->[0]`";
        } elsif (!ref($s)) {
            $t = $s;
        } else {
            $t = $s->[0];
            $cs0 = $s->[1];
        }
        my @clause_sets;
        my $cs = $schema->{clause_sets};
        if (defined($cs)) {
            if (ref($cs) ne 'ARRAY') {
                return "hash form 'clause_sets' key must be an arrayref";
            }
            for (0..@$cs-1) {
                if (ref($cs->[$_]) ne 'HASH') {
                    return "hash form 'clause_sets'[$_] must be a hashref";
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
                return "hash form 'def' key must be a hashref";
            }
        }
        $def //= {};
        for (keys %$schema) {
            return "hash form has unknown key `$_'" unless /^(type|clause_sets|def)$/;
        }
        return { type=>$t, clause_sets=>\@clause_sets, def=>$def };

    }

    return "schema must be a str, arrayref, or hashref";
}

1;
