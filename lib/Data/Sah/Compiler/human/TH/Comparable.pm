package Data::Sah::Compiler::human::TH::Comparable;

use 5.010;
use Log::Any '$log';
use Moo::Role;
with 'Data::Sah::Type::Comparable';

# VERSION

sub superclause_comparable {
    my ($self, $which, $cd) = @_;
    my $c = $self->compiler;

    my $fmt;
    if ($which eq 'is') {
        $c->add_ccl($cd, {expr=>1, multi=>1,
                          fmt => '%(modal_verb_be)s%s'});
    } elsif ($which eq 'in') {
        $c->add_ccl($cd, {expr=>1, multi=>1,
                          fmt => '%(modal_verb_be)sone of %s'});
    }
}
1;
# ABSTRACT: human's type handler for role "Comparable"

=for Pod::Coverage ^(clause_.+|superclause_.+)$
