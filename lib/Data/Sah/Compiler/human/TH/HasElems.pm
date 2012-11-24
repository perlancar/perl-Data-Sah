package Data::Sah::Compiler::human::TH::HasElems;

use 5.010;
use Log::Any '$log';
use Moo::Role;
with 'Data::Sah::Type::HasElems';

# VERSION

sub superclause_has_elems {
    my ($self_th, $which, $cd) = @_;
    my $c = $self_th->compiler;

    if ($which eq 'len') {
        #$c->add_ccl($cd, "\@{$dt} == $ct");
    } elsif ($which eq 'min_len') {
        #$c->add_ccl($cd, "\@{$dt} >= $ct");
    } elsif ($which eq 'max_len') {
        #$c->add_ccl($cd, "\@{$dt} <= $ct");
    } elsif ($which eq 'len_between') {
    } elsif ($which eq 'each_index') {
        $self_th->clause_each_index($cd);
    } elsif ($which eq 'each_elem') {
        $self_th->clause_each_elem($cd);
    #} elsif ($which eq 'check_each_index') {
    #} elsif ($which eq 'check_each_elem') {
    #} elsif ($which eq 'uniq') {
    #} elsif ($which eq 'exists') {
    }
}

1;
# ABSTRACT: human's type handler for role "HasElems"

=for Pod::Coverage ^(clause_.+|superclause_.+)$
