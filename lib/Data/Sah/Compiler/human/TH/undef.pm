package Data::Sah::Compiler::human::TH::undef;

# DATE
# VERSION

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Mo qw(build default);
use Role::Tiny::With;

extends 'Data::Sah::Compiler::human::TH';
with 'Data::Sah::Type::undef';

sub name { "undefined value" }

sub handle_type {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    $c->add_ccl($cd, {
        fmt   => ["undefined value", "undefined values"],
        type  => 'noun',
    });
}

1;
# ABSTRACT: perl's type handler for type "undef"

=for Pod::Coverage ^(name|clause_.+|superclause_.+|before_.+|after_.+)$
