package Data::Sah::Compiler::perl::TH::bool;

# DATE
# VERSION

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Mo qw(build default);
use Role::Tiny::With;

extends 'Data::Sah::Compiler::perl::TH';
with 'Data::Sah::Type::bool';

sub handle_type {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    my $dt = $cd->{data_term};
    $cd->{_ccl_check_type} = "!ref($dt)";
}

sub superclause_comparable {
    my ($self, $which, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    if ($which eq 'is') {
        $c->add_ccl($cd, "($dt ? 1:0) == ($ct ? 1:0)");
    } elsif ($which eq 'in') {
        if ($dt =~ /\$_\b/) {
            $c->add_ccl($cd, "do { my \$_sahv_dt = $dt; (grep { (\$_ ? 1:0) == (\$_sahv_dt ? 1:0) } \@{ $ct }) ? 1:0 }");
        } else {
            $c->add_ccl($cd, "(grep { (\$_ ? 1:0) == ($dt ? 1:0) } \@{ $ct }) ? 1:0");
        }
    }
}

sub superclause_sortable {
    my ($self, $which, $cd) = @_;
    my $c  = $self->compiler;
    my $cv = $cd->{cl_value};
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    if ($which eq 'min') {
        $c->add_ccl($cd, "($dt ? 1:0) >= ($ct ? 1:0)");
    } elsif ($which eq 'xmin') {
        $c->add_ccl($cd, "($dt ? 1:0) > ($ct ? 1:0)");
    } elsif ($which eq 'max') {
        $c->add_ccl($cd, "($dt ? 1:0) <= ($ct ? 1:0)");
    } elsif ($which eq 'xmax') {
        $c->add_ccl($cd, "($dt ? 1:0) < ($ct ? 1:0)");
    } elsif ($which eq 'between') {
        if ($cd->{cl_is_expr}) {
            $c->add_ccl($cd, "($dt ? 1:0) >= ($ct\->[0] ? 1:0) && ".
                            "($dt ? 1:0) <= ($ct\->[1] ? 1:0)");
        } else {
            # simplify code
            $c->add_ccl($cd, "($dt ? 1:0) >= ($cv->[0] ? 1:0) && ".
                            "($dt ? 1:0) <= ($cv->[1] ? 1:0)");
        }
    } elsif ($which eq 'xbetween') {
        if ($cd->{cl_is_expr}) {
            $c->add_ccl($cd, "($dt ? 1:0) > ($ct\->[0] ? 1:0) && ".
                            "($dt ? 1:0) < ($ct\->[1] ? 1:0)");
        } else {
            # simplify code
            $c->add_ccl($cd, "($dt ? 1:0) > ($cv->[0] ? 1:0) && ".
                            "($dt ? 1:0) < ($cv->[1] ? 1:0)");
        }
    }
}

sub clause_is_true {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    $c->add_ccl($cd, "($ct) ? $dt : !defined($ct) ? 1 : !$dt");
}

1;
# ABSTRACT: perl's type handler for type "bool"

=for Pod::Coverage ^(clause_.+|superclause_.+)$
