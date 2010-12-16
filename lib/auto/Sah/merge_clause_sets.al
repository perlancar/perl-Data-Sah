package Sah;

# split to defer loading Data::ModeMerge.

use 5.010;
use Data::ModeMerge;

sub merge_clause_sets {
    my ($self, $clause_sets) = @_;
    my @merged;
    my $res = {error=>''};

    my $mm = $self->merger;
    if (!$mm) {
        $mm = Data::ModeMerge->new(config=>{recurse_array=>1});
        $self->merger($mm);
    }

    my @c;
    for (@$clause_sets) {
        push @cs, {cs=>$_, has_prefix=>$mm->check_prefix_on_hash($_)};
    }
    for (reverse @cs) {
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
            ($c->{last_with_prefix} || $a[$i-1]{last_with_prefix}) ? 0 : 1);
        my $mres = $mm->merge($merged[-1], $c->{cs});
        if (!$mres->{success}) {
            $res->{error} = $mres->{error};
            last;
        }
        $merged[-1] = $mres->{result};
    }
    $res->{result} = \@merged unless $res->{error};
    $res->{success} = !$res->{error};
    $res;
}

1;
