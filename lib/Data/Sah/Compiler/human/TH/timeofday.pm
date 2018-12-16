package Data::Sah::Compiler::human::TH::timeofday;

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
with 'Data::Sah::Compiler::human::TH::Sortable';
with 'Data::Sah::Type::timeofday';

sub name { "time" }

sub handle_type {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    $c->add_ccl($cd, {type=>'noun', fmt => ["time", "times"]});
}

1;
# ABSTRACT: human's type handler for type "timeofday"

=for Pod::Coverage ^(name|clause_.+|superclause_.+|before_.+|after_.+)$
