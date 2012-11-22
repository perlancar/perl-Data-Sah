package Data::Sah::Compiler::human::TH::Sortable;

use 5.010;
use Log::Any '$log';
use Moo::Role;
with 'Data::Sah::Type::Sortable';

# VERSION

sub superclause_sortable {
    my ($self, $which, $cd) = @_;
    my $c = $self->compiler;

    my $cv = $cd->{cl_value};

    if ($which eq 'min') {
         $c->add_ccl($cd, {expr=>1, multi=>1,
                           fmt => '%(modal_verb_be)sat least %s'});
    } elsif ($which eq 'xmin') {
         $c->add_ccl($cd, {expr=>1, multi=>1,
                           fmt => '%(modal_verb_be)slarger than %s'});
    } elsif ($which eq 'max') {
         $c->add_ccl($cd, {expr=>1, multi=>1,
                           fmt => '%(modal_verb_be)sat most %s'});
    } elsif ($which eq 'xmax') {
         $c->add_ccl($cd, {expr=>1, multi=>1,
                           fmt => '%(modal_verb_be)ssmaller than %s'});
    } elsif ($which eq 'between') {
         $c->add_ccl($cd, {fmt => '%(modal_verb_be)sbetween %s and %s',
                           vals => $cv});
    } elsif ($which eq 'xbetween') {
         $c->add_ccl($cd, {
             fmt => '%(modal_verb_be)slarger than %s and smaller than %s',
             vals => $cv});
    }
}

1;
# ABSTRACT: human's type handler for role "Sortable"

=for Pod::Coverage ^(clause_.+|superclause_.+)$
