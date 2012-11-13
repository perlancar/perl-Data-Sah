package Data::Sah::Compiler::perl::str;

use 5.010;
use Log::Any '$log';
use Moo;
extends 'Data::Sah::Compiler::perl::TH';
with 'Data::Sah::Type::str';

# VERSION

sub handle_type {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    my $dt = $cd->{data_term};
    $cd->{_ccl_check_type} = "!ref($dt)";
}

sub superclause_comparable {
    my ($self, $which, $cd) = @_;
    my $c = $self->compiler;

    $c->handle_clause(
        $cd,
        on_term => sub {
            my ($self, $cd) = @_;
            my $ct = $cd->{cl_term};
            my $dt = $cd->{data_term};

            if ($which eq 'is') {
                $c->add_ccl($cd, "$dt eq $ct");
            } elsif ($which eq 'in') {
                $c->add_ccl($cd, "$dt ~~ $ct");
            }
        },
    );
}

sub superclause_sortable {
    my ($self, $which, $cd) = @_;
    my $c = $self->compiler;

    $c->handle_clause(
        $cd,
        on_term => sub {
            my ($self, $cd) = @_;
            my $cv = $cd->{cl_value};
            my $ct = $cd->{cl_term};
            my $dt = $cd->{data_term};

            if ($which eq 'min') {
                $c->add_ccl($cd, "$dt ge $ct");
            } elsif ($which eq 'xmin') {
                $c->add_ccl($cd, "$dt gt $ct");
            } elsif ($which eq 'max') {
                $c->add_ccl($cd, "$dt le $ct");
            } elsif ($which eq 'xmax') {
                $c->add_ccl($cd, "$dt lt $ct");
            } elsif ($which eq 'between') {
                if ($cd->{cl_is_expr}) {
                    $c->add_ccl($cd, "$dt ge $ct\->[0] && $dt le $ct\->[1]");
                } else {
                    # simplify code
                    $c->add_ccl($cd, "$dt ge ".$c->literal($cv->[0]).
                                    " && $dt le ".$c->literal($cv->[1]));
                }
            } elsif ($which eq 'xbetween') {
                if ($cd->{cl_is_expr}) {
                    $c->add_ccl($cd, "$dt gt $ct\->[0] && $dt lt $ct\->[1]");
                } else {
                    # simplify code
                    $c->add_ccl($cd, "$dt gt ".$c->literal($cv->[0]).
                                    " && $dt lt ".$c->literal($cv->[1]));
                }
            }
        },
    );
}

sub superclause_has_elems {
    my ($self_th, $which, $cd) = @_;
    my $c = $self_th->compiler;

    $c->handle_clause(
        $cd,
        on_term => sub {
            my ($self, $cd) = @_;
            my $cv = $cd->{cl_value};
            my $ct = $cd->{cl_term};
            my $dt = $cd->{data_term};

            if ($which eq 'len') {
                $c->add_ccl($cd, "length($dt) == $ct");
            } elsif ($which eq 'min_len') {
                $c->add_ccl($cd, "length($dt) >= $ct");
            } elsif ($which eq 'max_len') {
                $c->add_ccl($cd, "length($dt) <= $ct");
            } elsif ($which eq 'len_between') {
                if ($cd->{cl_is_expr}) {
                    $c->add_ccl(
                        $cd, "length($dt) >= $ct\->[0] && ".
                            "length($dt) >= $ct\->[1]");
                } else {
                    # simplify code
                    $c->add_ccl(
                        $cd, "length($dt) >= $cv->[0] && ".
                            "length($dt) <= $cv->[1]");
                }
            #} elsif ($which eq 'has') {
            } elsif ($which eq 'each_index' || $which eq 'each_elem') {
                $self_th->gen_each($which, $cd,
                                "0..length($dt)-1", "split('', $dt)");
            #} elsif ($which eq 'check_each_index') {
            #} elsif ($which eq 'check_each_elem') {
            #} elsif ($which eq 'uniq') {
            #} elsif ($which eq 'exists') {
            }
        },
    );
}

sub clause_match {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    $c->handle_clause(
        $cd,
        on_term => sub {
            my ($self, $cd) = @_;
            my $cv = $cd->{cl_value};
            my $ct = $cd->{cl_term};
            my $dt = $cd->{data_term};

            if ($cd->{cl_is_expr}) {
                $c->add_ccl($cd, join(
                    "",
                    "ref($ct) eq 'Regexp' ? $dt =~ $ct : ",
                    "do { my \$re = $ct; eval { \$re = /\$re/; 1 } && ",
                    "$dt =~ \$re }",
                ));
            } else {
                # simplify code and we can check regex at compile time
                my $re;
                if (ref($cv) eq 'Regexp') {
                    $re = $cv;
                } else {
                    eval { $re = qr/$cv/ };
                    $self->_die($cd, "Invalid regex $cv: $@") if $@;
                }

                # i don't know if this is safe?
                $re = "$re";
                $re =~ s!/!\\/!g;

                $c->add_ccl($cd, "$dt =~ /$re/");
            }
        },
    );
}

sub clause_is_re {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    $c->handle_clause(
        $cd,
        on_term => sub {
            my ($self, $cd) = @_;
            my $cv = $cd->{cl_value};
            my $ct = $cd->{cl_term};
            my $dt = $cd->{data_term};

            if ($cd->{cl_is_expr}) {
                $c->add_ccl($cd, join(
                    "",
                    "do { my \$re = $dt; ",
                    "(eval { \$re = qr/\$re/; 1 } ? 1:0) == ($ct ? 1:0) }",
                ));
            } else {
                # simplify code
                $c->add_ccl($cd, join(
                    "",
                    "do { my \$re = $dt; ",
                    ($cv ? "" : "!"), "(eval { \$re = qr/\$re/; 1 })",
                    "}",
                ));
            }
        },
    );
}

1;
# ABSTRACT: perl's type handler for type "str"

=cut
