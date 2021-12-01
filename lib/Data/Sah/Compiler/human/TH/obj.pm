package Data::Sah::Compiler::human::TH::obj;

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Mo qw(build default);
use Role::Tiny::With;

extends 'Data::Sah::Compiler::human::TH';
with 'Data::Sah::Type::obj';

# AUTHORITY
# DATE
# DIST
# VERSION

sub name { "object" }

sub handle_type {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    $c->add_ccl($cd, {
        fmt   => ["object", "objects"],
        type  => 'noun',
    });
}

sub clause_can {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $cv = $cd->{cl_value};

    $c->add_ccl($cd, {
        fmt   => q[%(modal_verb)s have method(s) %s],
        #expr  => 1, # weird
    });
}

sub clause_isa {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $cv = $cd->{cl_value};

    $c->add_ccl($cd, {
        fmt   => q[%(modal_verb)s be subclass of %s],
    });
}

1;
# ABSTRACT: perl's type handler for type "obj"

=for Pod::Coverage ^(name|clause_.+|superclause_.+|before_.+|after_.+)$
