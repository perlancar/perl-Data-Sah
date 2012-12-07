package Data::Sah::Compiler::human::TH::bool;

use 5.010;
use Log::Any '$log';
use Moo;
extends 'Data::Sah::Compiler::human::TH';
with 'Data::Sah::Compiler::human::TH::Comparable';
with 'Data::Sah::Compiler::human::TH::Sortable';
with 'Data::Sah::Type::bool';

# VERSION

sub handle_type {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    $c->add_ccl($cd, {
        fmt   => ["boolean", "booleans"],
        type  => 'noun',
    });
}

sub before_clause_is_true {
    my ($self, $cd) = @_;
    $cd->{CLAUSE_DO_MULTI} = 0;
}

sub clause_is_true {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $cv = $cd->{cl_value};

    $c->add_ccl($cd, {
        fmt   => $cv ? q[%(modal_verb)s be true] : q[%(modal_verb)s be false],
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
# ABSTRACT: perl's type handler for type "bool"

=for Pod::Coverage ^(clause_.+|superclause_.+)$
