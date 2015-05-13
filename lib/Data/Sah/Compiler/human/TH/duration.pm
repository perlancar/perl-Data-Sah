package Data::Sah::Compiler::human::TH::duration;

# DATE
# VERSION

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Mo qw(build default);
use Role::Tiny::With;

extends 'Data::Sah::Compiler::human::TH';
with 'Data::Sah::Type::duration';

sub name { "duration" }

sub handle_type {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    $c->add_ccl($cd, {type=>'noun', fmt => ["duration", "durations"]});
}

1;
# ABSTRACT: human's type handler for type "duration"

=for Pod::Coverage ^(name|clause_.+|superclause_.+|before_.+|after_.+)$
