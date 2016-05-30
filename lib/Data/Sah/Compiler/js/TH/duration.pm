package Data::Sah::Compiler::js::TH::duration;

# DATE
# VERSION

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Mo qw(build default);
use Role::Tiny::With;
use Scalar::Util qw(blessed looks_like_number);

extends 'Data::Sah::Compiler::js::TH';
with 'Data::Sah::Type::duration';

sub handle_type {
    my ($self, $cd) = @_;

    my $dt = $cd->{data_term};
    $cd->{_ccl_check_type} = join(
        ' && ',
        "typeof($dt) == 'number'",
        "$dt >= 0", # disallow negative duration
        "isFinite($dt)", # disallow infinite duration
    );
}

sub superclause_comparable {
    my ($self, $which, $cd) = @_;
    my $c  = $self->compiler;
    my $cv = $cd->{cl_value};
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    if ($which eq 'is') {
        $c->add_ccl($cd, "$dt === $ct");
    } elsif ($which eq 'in') {
        if ($cd->{cl_is_expr}) {
            # i'm lazy, technical debt
            $c->_die($cd, "duration's in clause with expression not yet supported");
        }
        $ct = '['.join(', ', map { "+($_)" } @$cv).']';
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
        $c->_die($cd, "duration's comparison with expression not yet supported");
    }

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
}

1;
# ABSTRACT: js's type handler for type "date"

=for Pod::Coverage ^(clause_.+|superclause_.+|handle_.+|before_.+|after_.+)$

=head1 DESCRIPTION

Currently the C<duration> Sah type is represented in JavaScript using number
(float, number of seconds). In the future, a choice of coercing to some duration
object might be supported, for richer manipulation, like L<DateTime::Duration>
in Perl.
