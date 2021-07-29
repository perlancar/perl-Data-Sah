package Data::Sah::Compiler::human::TH::str;

# DATE
# VERSION

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Mo qw(build default);
use Role::Tiny::With;

extends 'Data::Sah::Compiler::human::TH';
with 'Data::Sah::Compiler::human::TH::Sortable';
with 'Data::Sah::Compiler::human::TH::Comparable';
with 'Data::Sah::Compiler::human::TH::HasElems';
with 'Data::Sah::Type::str';

sub name { "text" }

sub handle_type {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    $c->add_ccl($cd, {
        fmt   => ["text", "texts"],
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
    $iargs{cache}                = $cd->{args}{cache};
    my $icd = $c->compile(%iargs);

    $c->add_ccl($cd, {
        type  => 'list',
        fmt   => 'each subscript of text %(modal_verb)s be',
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
    $iargs{cache}                = $cd->{args}{cache};
    my $icd = $c->compile(%iargs);

    $c->add_ccl($cd, {
        type  => 'list',
        fmt   => 'each character of the text %(modal_verb)s be',
        items => [
            $icd->{ccls},
        ],
        vals  => [],
    });
}

sub clause_encoding {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $cv = $cd->{cl_value};

    $c->_die($cd, "Only 'utf8' encoding is currently supported")
        unless $cv eq 'utf8';
    # currently does nothing
}

sub clause_match {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $cv = $cd->{cl_value};

    $c->add_ccl($cd, {
        fmt   => q[%(modal_verb)s match regex pattern %s],
        #expr  => 1, # weird
    });
}

sub clause_is_re {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $cv = $cd->{cl_value};

    $c->add_ccl($cd, {
        fmt   => q[%(modal_verb)s be a regex pattern],
    });
}

1;
# ABSTRACT: perl's type handler for type "str"

=for Pod::Coverage ^(name|clause_.+|superclause_.+|before_.+|after_.+)$
