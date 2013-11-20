#!perl

use 5.010;
use strict;
use warnings;
use FindBin '$Bin';
use lib "$Bin";

require "testlib.pl";
use Test::More 0.98;

my $node_path = get_nodejs_path();
unless ($node_path) {
    plan skip_all => 'node.js is not available';
}

run_spectest('js', {
    node_path=>$node_path,
    skip_if => sub {
        my $t = shift;
        return 0 unless $t->{tags};

        for (qw/req_keys req_keys_re
                allowed_keys allowed_keys_re
                forbidden_keys forbidden_keys_re
               /) {
            return "hash clause $_ not yet implemented"
                if all_match(["type:hash", "clause:$_"], $t->{tags});
        }

        0;
    },
});
done_testing();
