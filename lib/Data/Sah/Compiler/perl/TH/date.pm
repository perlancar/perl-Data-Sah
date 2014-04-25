package Data::Sah::Compiler::perl::TH::date;

use 5.010;
use Log::Any '$log';
use Moo;
use experimental 'smartmatch';
extends 'Data::Sah::Compiler::perl::TH';
with 'Data::Sah::Type::date';

use Scalar::Util qw(blessed looks_like_number);

# VERSION
# DATE

sub expr_coerce_term {
    my ($self, $cd, $t) = @_;

    my $c = $self->compiler;
    $c->add_module($cd, 'DateTime');
    $c->add_module($cd, 'Scalar::Util');

    join(
        '',
        "(",
        "(Scalar::Util::blessed($t) && $t->isa('DateTime')) ? $t : ",
        "(Scalar::Util::looks_like_number($t) && $t >= 10**8 && $t <= 2**31) ? DateTime->from_epoch($t) : ",
        "$t =~ /\\A([0-9]{4})-([0-9]{2})-([0-9]{2})\\z/ ? DateTime->new(year=>\$1, month=>\$2, day=>\$3) : die(\"BUG: can't coerce date\")",
        ")",
    );
}

sub expr_coerce_value {
    my ($self, $cd, $v) = @_;

    my $c = $self->compiler;
    $c->add_module($cd, 'DateTime');

    if (blessed($v) && $v->isa('DateTime')) {
        return join(
            '',
            "DateTime->new(",
            "year=>",   $v->year, ",",
            "month=>",  $v->month, ",",
            "day=>",    $v->day, ",",
            "hour=>",   $v->hour, ",",
            "minute=>", $v->minute, ",",
            "second=>", $v->second, ",",
            ")",
        );
    } elsif (looks_like_number($v) && $v >= 10**8 && $v <= 2**31) {
        return "DateTime->from_epoch($v)";
    } elsif ($v =~ /\A([0-9]{4})-([0-9]{2})-([0-9]{2})\z/) {
        require DateTime;
        eval { DateTime->new(year=>$1, month=>$2, day=>$3) ; 1 }
            or die "Invalid date literal '$v': $@";
        return "DateTime->new(year=>$1, month=>$2, day=>$3)";
    } else {
        die "Invalid date literal '$v'";
    }
}

sub handle_type {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $dt = $cd->{data_term};

    $c->add_module($cd, 'Scalar::Util');
    $cd->{_ccl_check_type} = join(
        '',
        "(Scalar::Util::blessed($dt) && $dt->isa('DateTime')) || ",
        "(Scalar::Util::looks_like_number($dt) && $dt >= 10**8 && $dt <= 2**31) || ",
        "($dt =~ /\\A([0-9]{4})-([0-9]{2})-([0-9]{2})\\z/ && eval { DateTime->new(year=>\$1, month=>\$2, day=>\$3); 1})",
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
        $c->add_ccl($cd, "DateTime->compare($dt, $ct)==0");
    } elsif ($which eq 'in') {
        $c->add_module('List::Util');
        if ($cd->{cl_is_expr}) {
            # i'm lazy, technical debt
            $c->_die($cd, "date's in clause with expression not yet supported");
        } else {
            $ct = join(', ', map { $self->expr_coerce_value($cd, $_) } @$cv);
        };
        $c->add_ccl($cd, "List::Util::first(sub{DateTime->compare($dt, \$_)==0}, $ct)");
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
        $c->add_ccl($cd, "DateTime->compare($dt, ".
                        $self->expr_coerce_value($cd, $cv).") >= 0");
    } elsif ($which eq 'xmin') {
        $c->add_ccl($cd, "DateTime->compare($dt, ".
                        $self->expr_coerce_value($cd, $cv).") > 0");
    } elsif ($which eq 'max') {
        $c->add_ccl($cd, "DateTime->compare($dt, ".
                        $self->expr_coerce_value($cd, $cv).") <= 0");
    } elsif ($which eq 'xmax') {
        $c->add_ccl($cd, "DateTime->compare($dt, ".
                        $self->expr_coerce_value($cd, $cv).") < 0");
    } elsif ($which eq 'between') {
        $c->add_ccl($cd,
                    join(
                        '',
                        "DateTime->compare($dt, ",
                        $self->expr_coerce_value($cd, $cv->[0]).") >= 0 && ",
                        "DateTime->compare($dt, ",
                        $self->expr_coerce_value($cd, $cv->[1]).") <= 0",
                    ));
    } elsif ($which eq 'xbetween') {
        $c->add_ccl($cd,
                    join(
                        '',
                        "DateTime->compare($dt, ",
                        $self->expr_coerce_value($cd, $cv->[0]).") > 0 && ",
                        "DateTime->compare($dt, ",
                        $self->expr_coerce_value($cd, $cv->[1]).") < 0",
                    ));
    }
}

1;
# ABSTRACT: perl's type handler for type "date"

=for Pod::Coverage ^(clause_.+|superclause_.+|handle_.+|before_.+|after_.+|expr_coerce_.+)$

=head1 DESCRIPTION

What constitutes a valid date value:

=over

=item * L<DateTime> object

=item * integers from 100 million to 2^31

For convenience, some integers are accepted and interpreted as Unix epoch (32
bit). They will be converted to DateTime objects during validation. The values
correspond to dates from Mar 3rd, 1973 to Jan 19, 2038 (Y2038).

Choosing 100 million (9 decimal digits) as the lower limit is to avoid parsing
numbers like 20141231 (8 digit) as YMD date.

=item * string in the form of "YYYY-MM-DD"

For convenience, string of this form, like C<2014-04-25> is accepted and will be
converted to DateTime object. Invalid dates like C<2014-04-31> will of course
fail the validation.

=back
