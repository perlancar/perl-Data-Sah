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

    my $coerce_to = $cd->{coerce_to};
    if ($coerce_to eq 'int(epoch)') {
        if ($which eq 'is') {
            $c->add_ccl($cd, "$dt == $ct");
        } elsif ($which eq 'in') {
            $c->add_module('List::Util');
            $c->add_ccl($cd, "List::Util::first(sub{$dt == \$_}, $ct)");
        }
    } elsif ($coerce_to eq 'DateTime') {
        if ($which eq 'is') {
            $c->add_ccl($cd, "DateTime->compare($dt, $ct)==0");
        } elsif ($which eq 'in') {
            $c->add_module('List::Util');
            $c->add_ccl($cd, "List::Util::first(sub{DateTime->compare($dt, \$_)==0}, $ct)");
        }
    } elsif ($coerce_to eq 'Time::Moment') {
        if ($which eq 'is') {
            $c->add_ccl($cd, "$dt\->compare($ct)==0");
        } elsif ($which eq 'in') {
            $c->add_module('List::Util');
            $c->add_ccl($cd, "List::Util::first(sub{$dt\->compare(\$_)==0}, $ct)");
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
        $c->_die($cd, "date's comparison with expression not yet supported");
    }

    my $coerce_to = $cd->{coerce_to};
    if ($coerce_to eq 'int(epoch)') {
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
    } elsif ($coerce_to eq 'DateTime') {
        if ($which eq 'min') {
            $c->add_ccl($cd, "DateTime->compare($dt, $cv) >= 0");
        } elsif ($which eq 'xmin') {
            $c->add_ccl($cd, "DateTime->compare($dt, $cv) > 0");
        } elsif ($which eq 'max') {
            $c->add_ccl($cd, "DateTime->compare($dt, $cv) <= 0");
        } elsif ($which eq 'xmax') {
            $c->add_ccl($cd, "DateTime->compare($dt, $cv) < 0");
        } elsif ($which eq 'between') {
            $c->add_ccl($cd, "DateTime->compare($dt, $cv->[0]) >= 0 && DateTime->compare($dt, $cv->[1]) <= 0");
        } elsif ($which eq 'xbetween') {
            $c->add_ccl($cd, "DateTime->compare($dt, $cv->[0]) >  0 && DateTime->compare($dt, $cv->[1]) <  0");
        }
    } elsif ($coerce_to eq 'Time::Moment') {
        if ($which eq 'min') {
            $c->add_ccl($cd, "$dt\->compare($cv) >= 0");
        } elsif ($which eq 'xmin') {
            $c->add_ccl($cd, "$dt\->compare($cv) > 0");
        } elsif ($which eq 'max') {
            $c->add_ccl($cd, "$dt\->compare($cv) <= 0");
        } elsif ($which eq 'xmax') {
            $c->add_ccl($cd, "$dt\->compare($cv) < 0");
        } elsif ($which eq 'between') {
            $c->add_ccl($cd, "$dt\->compre($cv->[0]) >= 0 && $dt\->compare($cv->[1]) <= 0");
        } elsif ($which eq 'xbetween') {
            $c->add_ccl($cd, "$dt\->compre($cv->[0]) >  0 && $dt\->compare($cv->[1]) <  0");
        }
    }
}

1;
# ABSTRACT: perl's type handler for type "date"

=for Pod::Coverage ^(clause_.+|superclause_.+|handle_.+|before_.+|after_.+)$

=head1 DESCRIPTION


=head1 COMPILATION DATA KEYS

=over

=item * B<coerce_to> => str

By default will be set to C<int(epoch)>. Other valid values include:
C<DateTime>, C<Time::Moment>.

=back
