package Data::Sah::Compiler::human::TH::str;

use 5.010;
use Log::Any '$log';
use Moo;
extends 'Data::Sah::Compiler::human::TH';
with 'Data::Sah::Compiler::human::TH::Sortable';
with 'Data::Sah::Compiler::human::TH::Comparable';
with 'Data::Sah::Compiler::human::TH::HasElems';
with 'Data::Sah::Type::str';

# VERSION

sub name { "text" }

sub handle_type {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    $c->add_ccl($cd, {
        fmt   => ["text", "texts"],
        type  => 'noun',
    });
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

=for Pod::Coverage ^(clause_.+|superclause_.+)$
