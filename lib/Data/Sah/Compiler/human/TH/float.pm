package Data::Sah::Compiler::human::TH::float;

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Mo qw(build default);
use Role::Tiny::With;

extends 'Data::Sah::Compiler::human::TH';
with 'Data::Sah::Compiler::human::TH::Comparable';
with 'Data::Sah::Compiler::human::TH::Sortable';
with 'Data::Sah::Type::float';

# AUTHORITY
# DATE
# DIST
# VERSION

sub name { "decimal number" }

sub handle_type {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    $c->add_ccl($cd, {
        type=>'noun',
        fmt => ["decimal number", "decimal numbers"],
    });
}

sub clause_is_nan {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    my $cv = $cd->{cl_value};
    if ($cd->{cl_is_expr}) {
        $c->add_ccl($cd, {});
    } else {
        $c->add_ccl($cd, {
            fmt => $cv ?
                q[%(modal_verb)s be a NaN] :
                    q[%(modal_verb_neg)s be a NaN],
        });
    }
}

sub clause_is_inf {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    my $cv = $cd->{cl_value};
    if ($cd->{cl_is_expr}) {
        $c->add_ccl($cd, {});
    } else {
        $c->add_ccl($cd, {
            fmt => $cv ?
                q[%(modal_verb)s an infinity] :
                    q[%(modal_verb_neg)s an infinity],
        });
    }
}

sub clause_is_pos_inf {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    my $cv = $cd->{cl_value};
    if ($cd->{cl_is_expr}) {
        $c->add_ccl($cd, {});
    } else {
        $c->add_ccl($cd, {
            fmt => $cv ?
                q[%(modal_verb)s a positive infinity] :
                    q[%(modal_verb_neg)s a positive infinity],
        });
    }
}

sub clause_is_neg_inf {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    my $cv = $cd->{cl_value};
    if ($cd->{cl_is_expr}) {
        $c->add_ccl($cd, {});
    } else {
        $c->add_ccl($cd, {
            fmt => $cv ?
                q[%(modal_verb)s a negative infinity] :
                    q[%(modal_verb_neg)s a negative infinity],
        });
    }
}

1;
# ABSTRACT: human's type handler for type "num"

=for Pod::Coverage ^(name|clause_.+|superclause_.+)$
