package Data::Sah::Compiler::human::TH::Comparable;

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Mo qw(build default);
use Role::Tiny;
use Role::Tiny::With;

with 'Data::Sah::Type::Comparable';

# AUTHORITY
# DATE
# DIST
# VERSION

sub superclause_comparable {
    my ($self, $which, $cd) = @_;
    my $c = $self->compiler;

    my $fmt;
    if ($which eq 'is') {
        $c->add_ccl($cd, {expr=>1, multi=>1,
                          fmt => '%(modal_verb)s have the value %s'});
    } elsif ($which eq 'in') {
        $c->add_ccl($cd, {expr=>1, multi=>1,
                          fmt => '%(modal_verb)s be one of %s'});
    }
}
1;
# ABSTRACT: human's type handler for role "Comparable"

=for Pod::Coverage ^(clause_.+|superclause_.+)$
