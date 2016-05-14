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

sub superclause_comparable {
    my ($self, $which, $cd) = @_;
    my $c  = $self->compiler;
    my $cv = $cd->{cl_value};
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    if ($which eq 'is') {
        if ($cd->{cl_is_expr}) {
            die "coercing clause value/term not yet reimplemented";
            #$ct = $self->expr_coerce_term($cd, $ct);
        } else {
            die "coercing clause value/term not yet reimplemented";
            #$ct = $self->expr_coerce_value($cd, $cv);
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
