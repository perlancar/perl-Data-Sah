package Data::Sah::Compiler::human::TH::hash;

# DATE
# VERSION

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Mo qw(build default);
use Role::Tiny::With;

extends 'Data::Sah::Compiler::human::TH';
with 'Data::Sah::Compiler::human::TH::Comparable';
with 'Data::Sah::Compiler::human::TH::HasElems';
with 'Data::Sah::Type::hash';

sub handle_type {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    $c->add_ccl($cd, {
        fmt   => ["hash", "hashes"],
        type  => 'noun',
    });
}

sub clause_has {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;

    $c->add_ccl($cd, {
        expr=>1, multi=>1,
        fmt => "%(modal_verb)s have %s in its %(field)s values"});
}

sub clause_each_index {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $cv = $cd->{cl_value};

    my %iargs = %{$cd->{args}};
    $iargs{outer_cd}             = $cd;
    $iargs{schema}               = $cv;
    $iargs{schema_is_normalized} = 0;
    my $icd = $c->compile(%iargs);

    $c->add_ccl($cd, {
        type  => 'list',
        fmt   => '%(field)s name %(modal_verb)s be',
        items => [
            $icd->{ccls},
        ],
        vals  => [],
    });
}

sub clause_each_elem {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $cv = $cd->{cl_value};

    my %iargs = %{$cd->{args}};
    $iargs{outer_cd}             = $cd;
    $iargs{schema}               = $cv;
    $iargs{schema_is_normalized} = 0;
    my $icd = $c->compile(%iargs);

    $c->add_ccl($cd, {
        type  => 'list',
        fmt   => 'each %(field)s %(modal_verb)s be',
        items => [
            $icd->{ccls},
        ],
        vals  => [],
    });
}

sub clause_keys {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $cv = $cd->{cl_value};

    for my $k (sort keys %$cv) {
        local $cd->{spath} = [@{$cd->{spath}}, $k];
        my $v = $cv->{$k};
        my %iargs = %{$cd->{args}};
        $iargs{outer_cd}             = $cd;
        $iargs{schema}               = $v;
        $iargs{schema_is_normalized} = 0;
        my $icd = $c->compile(%iargs);
        $c->add_ccl($cd, {
            type  => 'list',
            fmt   => '%(field)s %s %(modal_verb)s be',
            vals  => [$k],
            items => [ $icd->{ccls} ],
        });
    }
}

sub clause_re_keys {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $cv = $cd->{cl_value};

    for my $k (sort keys %$cv) {
        local $cd->{spath} = [@{$cd->{spath}}, $k];
        my $v = $cv->{$k};
        my %iargs = %{$cd->{args}};
        $iargs{outer_cd}             = $cd;
        $iargs{schema}               = $v;
        $iargs{schema_is_normalized} = 0;
        my $icd = $c->compile(%iargs);
        $c->add_ccl($cd, {
            type  => 'list',
            fmt   => '%(fields)s whose names match regex pattern %s %(modal_verb)s be',
            vals  => [$k],
            items => [ $icd->{ccls} ],
        });
    }
}

sub clause_req_keys {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;

    $c->add_ccl($cd, {
        fmt   => q[%(modal_verb)s have required %(fields)s %s],
        expr  => 1,
    });
}

sub clause_allowed_keys {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;

    $c->add_ccl($cd, {
        fmt   => q[%(modal_verb)s only have these allowed %(fields)s %s],
        expr  => 1,
    });
}

sub clause_allowed_keys_re {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;

    $c->add_ccl($cd, {
        fmt   => q[%(modal_verb)s only have %(fields)s matching regex pattern %s],
        expr  => 1,
    });
}

sub clause_forbidden_keys {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;

    $c->add_ccl($cd, {
        fmt   => q[%(modal_verb_neg)s have these forbidden %(fields)s %s],
        expr  => 1,
    });
}

sub clause_forbidden_keys_re {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;

    $c->add_ccl($cd, {
        fmt   => q[%(modal_verb_neg)s have %(fields)s matching regex pattern %s],
        expr  => 1,
    });
}

sub clause_choose_one_key {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;

    my $multi = $cd->{cl_is_multi};
    $cd->{cl_is_multi} = 0;

    my @ccls;
    for my $cv ($multi ? @{ $cd->{cl_value} } : ($cd->{cl_value})) {
        push @ccls, {
            fmt   => q[%(modal_verb)s contain at most one of these %(fields)s %s],
            vals  => [$cv],
        };
    }
    $c->add_ccl($cd, @ccls);
}

sub clause_choose_all_keys {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;

    my $multi = $cd->{cl_is_multi};
    $cd->{cl_is_multi} = 0;

    my @ccls;
    for my $cv ($multi ? @{ $cd->{cl_value} } : ($cd->{cl_value})) {
        push @ccls, {
            fmt   => q[%(modal_verb)s contain either none or all of these %(fields)s %s],
            vals  => [$cv],
        };
    }
    $c->add_ccl($cd, @ccls);
}

sub clause_req_one_key {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;

    my $multi = $cd->{cl_is_multi};
    $cd->{cl_is_multi} = 0;

    my @ccls;
    for my $cv ($multi ? @{ $cd->{cl_value} } : ($cd->{cl_value})) {
        push @ccls, {
            fmt   => q[%(modal_verb)s contain exactly one of these %(fields)s %s],
            vals  => [$cv],
        };
    }
    $c->add_ccl($cd, @ccls);
}

sub clause_req_some_keys {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;

    my $multi = $cd->{cl_is_multi};
    $cd->{cl_is_multi} = 0;

    my @ccls;
    for my $cv ($multi ? @{ $cd->{cl_value} } : ($cd->{cl_value})) {
        push @ccls, {
            fmt   => q[%(modal_verb)s contain between %d and %d of these %(fields)s %s],
            vals  => [$cv->[0], $cv->[1], $cv->[2]],
        };
    }
    $c->add_ccl($cd, @ccls);
}

sub clause_dep_any {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;

    my $multi = $cd->{cl_is_multi};
    $cd->{cl_is_multi} = 0;

    my @ccls;
    for my $cv ($multi ? @{ $cd->{cl_value} } : ($cd->{cl_value})) {
        if (@{ $cv->[1] } == 1) {
            push @ccls, {
                fmt   => q[%(field)s %2$s %(modal_verb)s be present before %(field)s %1$s can be present],
                vals  => [$cv->[0], $cv->[1][0]],
            };
        } else {
            push @ccls, {
                fmt   => q[one of %(fields)s %2$s %(modal_verb)s be present before %(field)s %1$s can be present],
                vals  => $cv,
                multi => 0,
            };
        }
    }
    $c->add_ccl($cd, @ccls);
}

sub clause_dep_all {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;

    my $multi = $cd->{cl_is_multi};
    $cd->{cl_is_multi} = 0;

    my @ccls;
    for my $cv ($multi ? @{ $cd->{cl_value} } : ($cd->{cl_value})) {
        if (@{ $cv->[1] } == 1) {
            push @ccls, {
                fmt   => q[%(field)s %2$s %(modal_verb)s be present before %(field)s %1$s can be present],
                vals  => [$cv->[0], $cv->[1][0]],
            };
        } else {
            push @ccls, {
                fmt   => q[all of %(fields)s %2$s %(modal_verb)s be present before %(field)s %1$s can be present],
                vals  => $cv,
            };
        }
    }
    $c->add_ccl($cd, @ccls);
}

sub clause_req_dep_any {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;

    my $multi = $cd->{cl_is_multi};
    $cd->{cl_is_multi} = 0;

    my @ccls;
    for my $cv ($multi ? @{ $cd->{cl_value} } : ($cd->{cl_value})) {
        if (@{ $cv->[1] } == 1) {
            push @ccls, {
                fmt   => q[%(field)s %1$s %(modal_verb)s be present when %(field)s %2$s is present],
                vals  => [$cv->[0], $cv->[1][0]],
            };
        } else {
            push @ccls, {
                fmt   => q[%(field)s %1$s %(modal_verb)s be present when one of %(fields)s %2$s is present],
                vals  => $cv,
            };
        }
    }
    $c->add_ccl($cd, @ccls);
}

sub clause_req_dep_all {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;

    my $multi = $cd->{cl_is_multi};
    $cd->{cl_is_multi} = 0;

    my @ccls;
    for my $cv ($multi ? @{ $cd->{cl_value} } : ($cd->{cl_value})) {
        if (@{ $cv->[1] } == 1) {
            push @ccls, {
                fmt   => q[%(field)s %1$s %(modal_verb)s be present when %(field)s %2$s is present],
                vals  => [$cv->[0], $cv->[1][0]],
            };
        } else {
            push @ccls, {
                fmt   => q[%(field)s %1$s %(modal_verb)s be present when all of %(fields)s %2$s are present],
                vals  => $cv,
            };
        }
    }
    $c->add_ccl($cd, @ccls);
}

sub after_clause {
    my ($self, $cd) = @_;

    # ignored attributes
    if ($cd->{clause} eq 'keys') {
        delete $cd->{uclset}{'keys.restrict'};
        delete $cd->{uclset}{'keys.create_default'};
    } elsif ($cd->{clause} eq 're_keys') {
        delete $cd->{uclset}{'re_keys.restrict'};
    }
}

1;
# ABSTRACT: human's type handler for type "hash"

=for Pod::Coverage ^(clause_.+|superclause_.+)$
