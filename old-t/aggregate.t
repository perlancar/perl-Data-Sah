#!perl
#!perl -T

# using Test::Aggregate is purely for speed. currently you can't use
# -T and plan mismatch in each aggregated test doesn't get caught.

use Test::Aggregate;

my $tests = Test::Aggregate->new({
   dirs => "t-a",
});
$tests->run;
