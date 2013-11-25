#!perl

use 5.010;
use strict;
use warnings;
use FindBin '$Bin';
use lib "$Bin";

use Data::Sah::JS;
use Test::More 0.98;
require "testlib.pl";

my $node_path = Data::Sah::JS::get_nodejs_path();
unless ($node_path) {
    plan skip_all => 'node.js is not available';
}

run_spectest('js', {
    node_path=>$node_path,
    skip_if => sub {
        my $t = shift;
        return 0 unless $t->{tags};

        for (qw/

                   check
                   check_each_elem
                   check_each_index
                   check_each_key
                   check_each_value
                   check_prop
                   exists
                   if
                   postfilters
                   prefilters
                   prop
                   uniq

               /) {
            return "clause $_ not yet implemented"
                if all_match(["clause:$_"], $t->{tags});

        }

        for (qw/isa/) {
            return "obj clause $_ not yet implemented"
                if all_match(["type:obj", "clause:$_"], $t->{tags});
        }

        return "properties are not yet implemented"
            if grep {/^prop:/} @{ $t->{tags} };

        0;
    },
});
done_testing();
