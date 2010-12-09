package Sah;

use 5.010;

sub normalize_schema {
    my ($self, $schema) = @_;

    if (!defined($schema)) {

        return "schema is missing";

    } elsif (!ref($schema)) {

        my $s = $self->_parse_shortcuts($schema);
        if (!defined($s)) {
            return "can't understand type name / parse shortcuts in string `$schema`";
        } elsif (!ref($s)) {
            return { type=>$s, attr_hashes=>[], def=>{} };
        } else {
            return { type=>$s->[0], attr_hashes=>[$s->[1]], def=>{} };
        }

    } elsif (ref($schema) eq 'ARRAY') {

        if (!defined($schema->[0])) {
            return "array form needs at least 1 element for type";
        } elsif (ref($schema->[0])) {
            return "array form's first element must be a string";
        }
        my $s = $self->_parse_shortcuts($schema->[0]);
        my $t;
        my $ah0;
        if (!defined($s)) {
            return "can't understand type name / parse shortcuts in first element `$schema->[0]`";
        } elsif (!ref($s)) {
            $t = $s;
            $ah0 = {};
        } else {
            $t = $s->[0];
            $ah0 = $s->[1];
        }
        my @attr_hashes;
        if (@$schema > 1) {
            for (1..@$schema-1) {
                if (ref($schema->[$_]) ne 'HASH') {
                    return "array form element [$_] (attrhash) must be a hashref";
                }
                my $ah = $_ == 1 ? {%$ah0, %{$schema->[1]}} : $schema->[$_];
                push @attr_hashes, $ah;
            }
        } else {
            push @attr_hashes, $ah0 if keys(%$ah0);
        }
        return { type=>$t, attr_hashes=>\@attr_hashes, def=>{} };

    } elsif (ref($schema) eq 'HASH') {

        if (!defined($schema->{type})) {
            return "hash form must have 'type' key";
        }
        my $s = $self->_parse_shortcuts($schema->{type});
        my $t;
        my $ah0;
        if (!defined($s)) {
            return "can't understand type name / parse shortcuts in 'type' value `$schema->[0]`";
        } elsif (!ref($s)) {
            $t = $s;
        } else {
            $t = $s->[0];
            $ah0 = $s->[1];
        }
        my @attr_hashes;
        $a = $schema->{attr_hashes};
        if (defined($a)) {
            if (ref($a) ne 'ARRAY') {
                return "hash form 'attr_hashes' key must be an arrayref";
            }
            for (0..@$a-1) {
                if (ref($a->[$_]) ne 'HASH') {
                    return "hash form 'attr_hashes'[$_] must be a hashref";
                }
                push @attr_hashes, $a->[$_];
            }
        }
        if ($ah0) {
            if (@attr_hashes) {
                $attr_hashes[0] = {%$ah0, %{$attr_hashes[0]}};
            } else {
                push @attr_hashes, $ah0;
            }
        }
        $a = $schema->{def};
        if (defined($a)) {
            if (ref($a) ne 'HASH') {
                return "hash form 'def' key must be a hashref";
            }
        }
        my $def = $a // {};
        for (keys %$schema) {
            return "hash form has unknown key `$_'" unless /^(type|attr_hashes|def)$/;
        }
        return { type=>$t, attr_hashes=>\@attr_hashes, def=>$def };

    }

    return "schema must be a str, arrayref, or hashref";
}

1;
