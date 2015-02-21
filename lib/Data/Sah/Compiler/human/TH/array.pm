package Data::Sah::Compiler::human::TH::array;

# DATE
# VERSION

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Mo qw(build default);
use Role::Tiny::With;

extends 'Data::Sah::Compiler::human::TH';
with 'Data::Sah::Compiler::human::TH::Comparable';
with 'Data::Sah::Compiler::human::TH::HasElems';
with 'Data::Sah::Type::array';

sub handle_type {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    $c->add_ccl($cd, {
        fmt   => ["array", "arrays"],
        type  => 'noun',
    });
}

sub clause_each_index {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $cv = $cd->{cl_value};

    my %iargs = %{$cd->{args}};
    $iargs{outer_cd}             = $cd;
    $iargs{schema}               = $cv;
    $iargs{schema_is_normalized} = 0;
    my $icd = $c->compile(%iargs);

    $c->add_ccl($cd, {
        type  => 'list',
        fmt   => 'each array subscript %(modal_verb)s be',
        items => [
            $icd->{ccls},
        ],
        vals  => [],
    });
}

sub clause_each_elem {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $cv = $cd->{cl_value};

    my %iargs = %{$cd->{args}};
    $iargs{outer_cd}             = $cd;
    $iargs{schema}               = $cv;
    $iargs{schema_is_normalized} = 0;
    my $icd = $c->compile(%iargs);

    # can we say 'array of INOUNS', e.g. 'array of integers'?
    if (@{$icd->{ccls}} == 1) {
        my $c0 = $icd->{ccls}[0];
        if ($c0->{type} eq 'noun' && ref($c0->{text}) eq 'ARRAY' &&
                @{$c0->{text}} > 1 && @{$cd->{ccls}} &&
                    $cd->{ccls}[0]{type} eq 'noun') {
            for (ref($cd->{ccls}[0]{text}) eq 'ARRAY' ?
                     @{$cd->{ccls}[0]{text}} : ($cd->{ccls}[0]{text})) {
                my $fmt = $c->_xlt($cd, '%s of %s');
                $_ = sprintf $fmt, $_, $c0->{text}[1];
            }
            return;
        }
    }

    # nope, we can't
    $c->add_ccl($cd, {
        type  => 'list',
        fmt   => 'each array element %(modal_verb)s be',
        items => [
            $icd->{ccls},
        ],
        vals  => [],
    });
}

sub clause_elems {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $cv = $cd->{cl_value};

    for my $i (0..@$cv-1) {
        local $cd->{spath} = [@{$cd->{spath}}, $i];
        my $v = $cv->[$i];
        my %iargs = %{$cd->{args}};
        $iargs{outer_cd}             = $cd;
        $iargs{schema}               = $v;
        $iargs{schema_is_normalized} = 0;
        my $icd = $c->compile(%iargs);
        $c->add_ccl($cd, {
            type  => 'list',
            fmt   => '%s %(modal_verb)s be',
            vals  => [
                $c->_ordinate($cd, $i+1, $c->_xlt($cd, "element")),
            ],
            items => [ $icd->{ccls} ],
        });
    }
}

1;
# ABSTRACT: human's type handler for type "array"

=for Pod::Coverage ^(clause_.+|superclause_.+)$
