package Data::Sah::Compiler::perl::TH::duration;

# DATE
# VERSION

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Mo qw(build default);
use Role::Tiny::With;
use Scalar::Util qw(blessed looks_like_number);

extends 'Data::Sah::Compiler::perl::TH';
with 'Data::Sah::Type::duration';

sub handle_type {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $dt = $cd->{data_term};

    $cd->{coerce_to} = $cd->{nschema}[1]{"x.perl.coerce_to"} // 'float(secs)';

    my $coerce_to = $cd->{coerce_to};

    if ($coerce_to eq 'float(secs)') {
        $cd->{_ccl_check_type} = "!ref($dt) && $dt =~ /\\A[0-9]+(?:\.[0-9]+)?\\z/"; # XXX no support exp notation for yet?
    } elsif ($coerce_to eq 'DateTime::Duration') {
        $c->add_runtime_module($cd, 'Scalar::Util');
        $cd->{_ccl_check_type} = "Scalar::Util::blessed($dt) && $dt\->isa('DateTime::Duration')";
    } else {
        die "BUG: Unknown coerce_to value '$coerce_to', use either ".
            "float(secs) or DateTime::Duration";
    }
}

sub superclause_comparable {
    my ($self, $which, $cd) = @_;
    my $c  = $self->compiler;
    my $cv = $cd->{cl_value};
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    if ($cd->{cl_is_expr}) {
        # i'm lazy, technical debt
        $c->_die($cd, "duration's comparison with expression not yet supported");
    }

    my $coerce_to = $cd->{coerce_to};
    if ($coerce_to eq 'float(secs)') {
        if ($which eq 'is') {
            $c->add_ccl($cd, "$dt == $ct"); # XXX yeah we're not supposed to use == with floats
        } elsif ($which eq 'in') {
            $c->add_runtime_module('List::Util');
            $c->add_ccl($cd, "List::Util::first(sub{$dt == \$_}, $ct)"); # XXX yeah we're not supposed to use == with floats
        }
    } elsif ($coerce_to eq 'DateTime::Duration') {
        # we need to express this like this because if we just use the raw $cv
        # (dump) it will be unwieldy
        my $ect = join(
            "",
            "DateTime::Duration->new(",
            "years => "  .$cv->years.",",
            "months => " .$cv->months.",",
            "weeks => "  .$cv->weeks.",",
            "days => "   .$cv->days.",",
            "hours => "  .$cv->hours.",",
            "minutes => ".$cv->minutes.",",
            "seconds => ".$cv->seconds.",",
            ")",
        );

        if ($which eq 'is') {
            $c->add_ccl($cd, "DateTime::Duration->compare($dt, $ect)==0");
        } elsif ($which eq 'in') {
            $c->add_runtime_module('List::Util');
            $c->add_ccl($cd, "List::Util::first(sub{DateTime::Duration->compare($dt, \$_)==0}, $ect)");
        }
    }
}

sub superclause_sortable {
    my ($self, $which, $cd) = @_;
    my $c  = $self->compiler;
    my $cv = $cd->{cl_value};
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    if ($cd->{cl_is_expr}) {
        # i'm lazy, technical debt
        $c->_die($cd, "duration's comparison with expression not yet supported");
    }

    my $coerce_to = $cd->{coerce_to};
    if ($coerce_to eq 'float(secs)') {
        if ($which eq 'min') {
            $c->add_ccl($cd, "$dt >= $cv");
        } elsif ($which eq 'xmin') {
            $c->add_ccl($cd, "$dt > $cv");
        } elsif ($which eq 'max') {
            $c->add_ccl($cd, "$dt <= $cv");
        } elsif ($which eq 'xmax') {
            $c->add_ccl($cd, "$dt < $cv");
        } elsif ($which eq 'between') {
            $c->add_ccl($cd, "$dt >= $cv->[0] && $dt <= $cv->[1]");
        } elsif ($which eq 'xbetween') {
            $c->add_ccl($cd, "$dt >  $cv->[0] && $dt <  $cv->[1]");
        }
    } elsif ($coerce_to eq 'DateTime::Duration') {
        # we need to express this like this because if we just use the raw $cv
        # (dump) it will be unwieldy
        my ($ect, $ect0, $ect1);
        if (ref($cv) eq 'ARRAY') {
            $ect0 = join(
                "",
                "DateTime::Duration->new(",
                "years => "  .$cv->[0]->years.",",
                "months => " .$cv->[0]->months.",",
                "weeks => "  .$cv->[0]->weeks.",",
                "days => "   .$cv->[0]->days.",",
                "hours => "  .$cv->[0]->hours.",",
                "minutes => ".$cv->[0]->minutes.",",
                "seconds => ".$cv->[0]->seconds.",",
                ")",
            );
            $ect1 = join(
                "",
                "DateTime::Duration->new(",
                "years => "  .$cv->[1]->years.",",
                "months => " .$cv->[1]->months.",",
                "weeks => "  .$cv->[1]->weeks.",",
                "days => "   .$cv->[1]->days.",",
                "hours => "  .$cv->[1]->hours.",",
                "minutes => ".$cv->[1]->minutes.",",
                "seconds => ".$cv->[1]->seconds.",",
                ")",
            );
        } else {
            $ect = join(
                "",
                "DateTime::Duration->new(",
                "years => "  .$cv->years.",",
                "months => " .$cv->months.",",
                "weeks => "  .$cv->weeks.",",
                "days => "   .$cv->days.",",
                "hours => "  .$cv->hours.",",
                "minutes => ".$cv->minutes.",",
                "seconds => ".$cv->seconds.",",
                ")",
            );
        }

        if ($which eq 'min') {
            $c->add_ccl($cd, "DateTime->compare($dt, $ect) >= 0");
        } elsif ($which eq 'xmin') {
            $c->add_ccl($cd, "DateTime->compare($dt, $ect) > 0");
        } elsif ($which eq 'max') {
            $c->add_ccl($cd, "DateTime->compare($dt, $ect) <= 0");
        } elsif ($which eq 'xmax') {
            $c->add_ccl($cd, "DateTime->compare($dt, $ect) < 0");
        } elsif ($which eq 'between') {
            $c->add_ccl($cd, "DateTime->compare($dt, $ect0) >= 0 && DateTime->compare($dt, $ect1) <= 0");
        } elsif ($which eq 'xbetween') {
            $c->add_ccl($cd, "DateTime->compare($dt, $ect0) >  0 && DateTime->compare($dt, $ect1) <  0");
        }
    }
}

1;
# ABSTRACT: perl's type handler for type "duration"

=for Pod::Coverage ^(clause_.+|superclause_.+|handle_.+|before_.+|after_.+)$

=head1 DESCRIPTION

The C<duration> type in perl can be represented one of two choices: float
(secs), or L<DateTime::Duration> object.
