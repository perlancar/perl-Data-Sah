package Data::Sah;

# split to defer loading Data::ModeMerge

use 5.010;
use strict;
use warnings;
use Data::ModeMerge;
use Log::Any qw($log);

sub _merge_clause_sets {
    my ($self, @clause_sets) = @_;
    my @merged;

    my $mm = $self->_merger;
    if (!$mm) {
        $mm = Data::ModeMerge->new(config => {
            recurse_array => 1,
        });
        $mm->modes->{NORMAL}  ->prefix   ('[merge]');
        $mm->modes->{NORMAL}  ->prefix_re(qr/\A\[merge\]/);
        $mm->modes->{ADD}     ->prefix   ('[merge+]');
        $mm->modes->{ADD}     ->prefix_re(qr/\A\[merge\+\]/);
        $mm->modes->{CONCAT}  ->prefix   ('[merge.]');
        $mm->modes->{CONCAT}  ->prefix_re(qr/\A\[merge\.\]/);
        $mm->modes->{SUBTRACT}->prefix   ('[merge-]');
        $mm->modes->{SUBTRACT}->prefix_re(qr/\A\[merge-\]/);
        $mm->modes->{DELETE}  ->prefix   ('[merge!]');
        $mm->modes->{DELETE}  ->prefix_re(qr/\A\[merge!\]/);
        $mm->modes->{KEEP}    ->prefix   ('[merge^]');
        $mm->modes->{KEEP}    ->prefix_re(qr/\A\[merge\^\]/);
        $self->_merger($mm);
    }

    my @c;
    for (@clause_sets) {
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
