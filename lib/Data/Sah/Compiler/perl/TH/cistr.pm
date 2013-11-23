package Data::Sah::Compiler::perl::TH::cistr;

use 5.010;
use Log::Any '$log';
use Moo;
extends 'Data::Sah::Compiler::perl::TH::str';
with 'Data::Sah::Type::cistr';

# VERSION

# XXX cache lc() result so it's not done on every clause

sub superclause_comparable {
    my ($self, $which, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    if ($which eq 'is') {
        $c->add_ccl($cd, "lc($dt) eq lc($ct)");
    } elsif ($which eq 'in') {
        $c->add_smartmatch_pragma($cd);
        $c->add_ccl($cd, "lc($dt) ~~ [map {lc} \@{ $ct }]");
    }
}

sub superclause_sortable {
    my ($self, $which, $cd) = @_;
    my $c  = $self->compiler;
    my $cv = $cd->{cl_value};
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    if ($which eq 'min') {
        $c->add_ccl($cd, "lc($dt) ge lc($ct)");
    } elsif ($which eq 'xmin') {
        $c->add_ccl($cd, "lc($dt) gt lc($ct)");
    } elsif ($which eq 'max') {
        $c->add_ccl($cd, "lc($dt) le lc($ct)");
    } elsif ($which eq 'xmax') {
        $c->add_ccl($cd, "lc($dt) lt lc($ct)");
    } elsif ($which eq 'between') {
        if ($cd->{cl_is_expr}) {
            $c->add_ccl($cd, "lc($dt) ge lc($ct\->[0]) && ".
                            "lc($dt) le lc($ct\->[1])");
        } else {
            # simplify code
            $c->add_ccl($cd, "lc($dt) ge ".$c->literal(lc $cv->[0]).
                            " && lc($dt) le ".$c->literal(lc $cv->[1]));
        }
    } elsif ($which eq 'xbetween') {
        if ($cd->{cl_is_expr}) {
            $c->add_ccl($cd, "lc($dt) gt lc($ct\->[0]) && ".
                            "lc($dt) lt lc($ct\->[1])");
        } else {
            # simplify code
            $c->add_ccl($cd, "lc($dt) gt ".$c->literal(lc $cv->[0]).
                            " && lc($dt) lt ".$c->literal(lc $cv->[1]));
        }
    }
}

sub clause_match {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $cv = $cd->{cl_value};
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    if ($cd->{cl_is_expr}) {
        $c->add_ccl($cd, join(
            "",
            "ref($ct) eq 'Regexp' ? $dt =~ qr/$ct/i : ",
            "do { my \$re = $ct; eval { \$re = /\$re/i; 1 } && ",
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

        $c->add_ccl($cd, "$dt =~ /$re/i");
    }
}

1;
# ABSTRACT: perl's type handler for type "cistr"

=for Pod::Coverage ^(clause_.+|superclause_.+)$
