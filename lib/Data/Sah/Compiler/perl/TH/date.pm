package Data::Sah::Compiler::perl::TH::date;

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
with 'Data::Sah::Type::date';

sub expr_coerce_term {
    my ($self, $cd, $t) = @_;

    my $c = $self->compiler;

    # to reduce unnecessary overhead, we don't explicitly load DateTime here,
    # but on demand when doing validation
    #$c->add_module($cd, 'DateTime');
    $c->add_module($cd, 'Scalar::Util');

    join(
        '',
        "(",
        "(Scalar::Util::blessed($t) && $t->isa('DateTime')) ? $t : ",
        "(Scalar::Util::looks_like_number($t) && $t >= 10**8 && $t <= 2**31) ? (require DateTime && DateTime->from_epoch(epoch=>$t)) : ",
        "$t =~ /\\A([0-9]{4})-([0-9]{2})-([0-9]{2})T([0-9]{2}):([0-9]{2}):([0-9]{2})Z\\z/ ? require DateTime && DateTime->new(year=>\$1, month=>\$2, day=>\$3, hour=>\$4, minute=>\$5, second=>\$6, time_zone=>'UTC') : ",
        "$t =~ /\\A([0-9]{4})-([0-9]{2})-([0-9]{2})\\z/ ? require DateTime && DateTime->new(year=>\$1, month=>\$2, day=>\$3, time_zone=>'UTC') : die(\"BUG: can't coerce date\")",
        ")",
    );
}

sub expr_coerce_value {
    my ($self, $cd, $v) = @_;

    my $c = $self->compiler;

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
            "timezone=>'UTC',",
            ")",
        );
    } elsif (looks_like_number($v) && $v >= 10**8 && $v <= 2**31) {
        return "require DateTime && DateTime->from_epoch(epoch=>$v)";
    } elsif ($v =~ /\A([0-9]{4})-([0-9]{2})-([0-9]{2})T([0-9]{2}):([0-9]{2}):([0-9]{2})Z\z/) {
        require DateTime;
        eval { DateTime->new(year=>$1, month=>$2, day=>$3,
                             hour=>$4, minute=>$5, second=>$6,
                             time_zone=>'UTC') ; 1 }
            or die "Invalid date literal '$v': $@";
        return "DateTime->new(year=>$1, month=>$2, day=>$3, hour=>$4, minute=>$5, second=>$6, time_zone=>'UTC')";
    } elsif ($v =~ /\A([0-9]{4})-([0-9]{2})-([0-9]{2})\z/) {
        require DateTime;
        eval { DateTime->new(year=>$1, month=>$2, day=>$3, time_zone=>'UTC') ; 1 }
            or die "Invalid date literal '$v': $@";
        return "DateTime->new(year=>$1, month=>$2, day=>$3, time_zone=>'UTC')";
    } else {
        die "Invalid date literal '$v'";
    }
}

sub handle_type {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $dt = $cd->{data_term};

    $cd->{coerce_to} = $cd->{nschema}[1]{"x.coerce_to"} // 'int(epoch)';
    my $coerce_to = $cd->{coerce_to};

    if ($coerce_to eq 'int(epoch)') {
        $cd->{_ccl_check_type} = "!ref($dt) && $dt =~ /\\A[0-9]+\\z/";
    } elsif ($coerce_to eq 'DateTime') {
        $c->add_module($cd, 'Scalar::Util');
        $cd->{_ccl_check_type} = "Scalar::Util::blessed($dt) && $dt\->isa('DateTime')";
    } elsif ($coerce_to eq 'Time::Moment') {
        $c->add_module($cd, 'Scalar::Util');
        $cd->{_ccl_check_type} = "Scalar::Util::blessed($dt) && $dt\->isa('Time::Moment')";
    } else {
        die "BUG: Unknown coerce_to value '$coerce_to'";
    }
}

sub before_all_clauses {
    my ($self, $cd) = @_;
    my $c = $self->compiler;
    my $dt = $cd->{data_term};

    # coerce to DateTime object during validation
    $self->set_tmp_data_term($cd, $self->expr_coerce_term($cd, $dt))
        if $cd->{has_constraint_clause}; # remember to sync with after_all_clauses()
}

sub after_all_clauses {
    my ($self, $cd) = @_;
    my $c = $self->compiler;
    my $dt = $cd->{data_term};

    $self->restore_data_term($cd)
        if $cd->{has_constraint_clause};
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


=head1 COMPILATION DATA KEYS

=over

=item * B<coerce_to> => str

By default will be set to C<int(epoch)>. Other valid values include:
C<DateTime>, C<Time::Moment>.

=back
