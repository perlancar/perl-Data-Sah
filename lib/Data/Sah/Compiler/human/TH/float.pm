package Data::Sah::Compiler::human::TH::float;

use 5.010;
use Log::Any '$log';
use Moo;
extends 'Data::Sah::Compiler::human::TH';
with 'Data::Sah::Compiler::human::TH::Comparable';
with 'Data::Sah::Compiler::human::TH::Sortable';
with 'Data::Sah::Type::float';

# VERSION

sub handle_type {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    $c->add_ccl($cd, {type=>'noun', fmt => ["decimal number", "decimal numbers"]});
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
                q[%(modal_verb_be)sa NaN] :
                    q[%(modal_verb_not_be)sa NaN],
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
                q[%(modal_verb_be)san infinity] :
                    q[%(modal_verb_not_be)san infinity],
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
                q[%(modal_verb_be)sa positive infinity] :
                    q[%(modal_verb_not_be)sa positive infinity],
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
                q[%(modal_verb_be)sa negative infinity] :
                    q[%(modal_verb_not_be)sa negative infinity],
        });
    }
}

1;
# ABSTRACT: human's type handler for type "num"

=for Pod::Coverage ^(clause_.+|superclause_.+)$
