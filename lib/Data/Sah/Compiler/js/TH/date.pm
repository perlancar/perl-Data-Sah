package Data::Sah::Compiler::js::TH::date;

use 5.010;
use Log::Any '$log';
use Moo;
extends 'Data::Sah::Compiler::js::TH';
with 'Data::Sah::Type::date';

use Scalar::Util qw(blessed looks_like_number);

# VERSION
# DATE

my $epoch_low  = 10**8;
my $epoch_high = 2**31;

# Date() accept these arguments:
# - Date(milliseconds epoch)
# - Date(year, month, date, hour, minute, sec, millisec) tapi year=114 utk 2014, month=0 utk jan
# - Date(datestring)
# - Date(another Date object)
# if arguments are invalid, Date() will still return a Date object,
# but if we try to do d.getMonth() or d.getYear() it will return NaN
#
# to compare 2 date, we can use d1 > d2, d1 < d2, but for anything
# involving =, we need to prefix using +: +d1 === +d2.

sub expr_coerce_term {
    my ($self, $cd, $t) = @_;

    join(
        '',
        "(",
        "($t instanceof Date) ? $t : ",
        "typeof($t)=='number' ? (new Date($t * 1000)) : ",
        "parseFloat($t)==$t   ? (new Date(parseFloat($t)) * 1000) : ",
        "(new Date($t))",
        ")",
    );
}

sub expr_coerce_value {
    my ($self, $cd, $v) = @_;

    if (blessed($v) && $v->isa('DateTime')) {
        return join(
            '',
            "(new Date(",
            $v->year, ",",
            $v->month, ",",
            $v->day, ",",
            $v->hour, ",",
            $v->minute, ",",
            $v->second, ",",
            $v->millisecond,
            "))",
        );
    } elsif (looks_like_number($v) && $v >= 10**8 && $v <= 2**31) {
        return "(new Date($v*1000))";
    } elsif ($v =~ /\A([0-9]{4})-([0-9]{2})-([0-9]{2})\z/) {
        require DateTime;
        eval { DateTime->new(year=>$1, month=>$2, day=>$3) ; 1 }
            or die "Invalid date literal '$v': $@";
        return "(new Date(\"$v\"))";
    } else {
        die "Invalid date literal '$v'";
    }
}

sub handle_type {
    my ($self, $cd) = @_;

    my $dt = $cd->{data_term};
    $cd->{_ccl_check_type} = join(
        '',
        "(",
        "typeof($dt)=='number' ? ($dt >= $epoch_low && $dt <= $epoch_high) : ",
        "parseFloat($dt)==$dt ? (parseFloat($dt) >= $epoch_low && parseFloat($dt) <= $epoch_high) : ",
        "!isNaN((new Date($dt)).getYear())",
        ")",
    );
}

sub before_all_clauses {
    my ($self, $cd) = @_;
    my $c = $self->compiler;
    my $dt = $cd->{data_term};

    # XXX only do this when there are clauses

    # coerce to DateTime object during validation
    $self->set_tmp_data_term($cd, $self->expr_coerce_term($cd, $dt));
}

sub after_all_clauses {
    my ($self, $cd) = @_;
    my $c = $self->compiler;
    my $dt = $cd->{data_term};

    $self->restore_data_term($cd);
}

sub superclause_comparable {
    my ($self, $which, $cd) = @_;
    my $c  = $self->compiler;
    my $cv = $cd->{cl_value};
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    if ($which eq 'is') {
        if ($cd->{cl_is_expr}) {
            $ct = $self->expr_coerce_term($cd, $ct);
        } else {
            $ct = $self->expr_coerce_value($cd, $cv);
        }
        $c->add_ccl($cd, "+($dt) === +($ct)");
    } elsif ($which eq 'in') {
        $c->add_module('List::Util');
        if ($cd->{cl_is_expr}) {
            # i'm lazy, technical debt
            $c->_die($cd, "date's in clause with expression not yet supported");
        }
        $ct = '['.join(', ', map { "+(".$self->expr_coerce_value($cd, $_).")" } @$ct).']';
        $c->add_ccl($cd, "($ct).indexOf(+($dt)) > -1");
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
        $c->_die($cd, "date's comparison with expression not yet supported");
    }

    if ($which eq 'min') {
        $c->add_ccl($cd, "+($dt) >= +(".$self->expr_coerce_value($cd, $cv).")");
    } elsif ($which eq 'xmin') {
        $c->add_ccl($cd, "+($dt) > +(".$self->expr_coerce_value($cd, $cv).")");
    } elsif ($which eq 'max') {
        $c->add_ccl($cd, "+($dt) <= +(".$self->expr_coerce_value($cd, $cv).")");
    } elsif ($which eq 'xmax') {
        $c->add_ccl($cd, "+($dt) < +(".$self->expr_coerce_value($cd, $cv).")");
    } elsif ($which eq 'between') {
        $c->add_ccl($cd, "+($dt) >= +(".$self->expr_coerce_value($cd, $cv->[0]).") && ".
                        "+($dt) <= +(".$self->expr_coerce_value($cd, $cv->[1]).")");
    } elsif ($which eq 'xbetween') {
        $c->add_ccl($cd, "+($dt) > +(".$self->expr_coerce_value($cd, $cv->[0]).") && ".
                        "+($dt) < +(".$self->expr_coerce_value($cd, $cv->[1]).")");
    }
}

1;
# ABSTRACT: js's type handler for type "date"

=for Pod::Coverage ^(clause_.+|superclause_.+|handle_.+|before_.+|after_.+|expr_coerce_.+)$
