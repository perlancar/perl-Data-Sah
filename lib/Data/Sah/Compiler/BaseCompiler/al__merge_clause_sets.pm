package Data::Sah;

# split to defer loading Data::ModeMerge

use 5.010;
use strict;
use warnings;
use Data::ModeMerge;
use Log::Any qw($log);

sub _merge_clause_sets {
    my ($self, $clause_sets) = @_;
    my @merged;

    my $mm = $self->merger;
    if (!$mm) {
        $mm = Data::ModeMerge->new(config=>{recurse_array=>1});
        $self->merger($mm);
    }

    my @c;
    for (@$clause_sets) {
        push @c, {cs=>$_, has_prefix=>$mm->check_prefix_on_hash($_)};
    }
    for (reverse @c) {
        if ($_->{has_prefix}) { $_->{last_with_prefix} = 1; last }
    }

    my $i = -1;
    for my $c (@c) {
        $i++;
        if (!$i || !$c->{has_prefix} && !$c[$i-1]{has_prefix}) {
            push @merged, $c->{cs};
            next;
        }
        $mm->config->readd_prefix(
            ($c->{last_with_prefix} || $c[$i-1]{last_with_prefix}) ? 0 : 1);
        my $mres = $mm->merge($merged[-1], $c->{cs});
        die "Can't merge clause sets: $mres->{error}" unless $mres->{success};
        $merged[-1] = $mres->{result};
    }
    \@merged;
}

1;
