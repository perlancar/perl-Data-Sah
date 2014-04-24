package Data::Sah::Compiler::human::TH::date;

use 5.010;
use Log::Any '$log';
use Moo;
extends 'Data::Sah::Compiler::human::TH';
with 'Data::Sah::Compiler::human::TH::Comparable';
with 'Data::Sah::Compiler::human::TH::Sortable';
with 'Data::Sah::Type::date';

# VERSION

sub name { "date" }

sub handle_type {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    $c->add_ccl($cd, {type=>'noun', fmt => ["date", "dates"]});
}

1;
# ABSTRACT: human's type handler for type "date"

=for Pod::Coverage ^(name|clause_.+|superclause_.+|before_.+|after_.+)$
