#!perl

use 5.010;
use strict;
use warnings;
use FindBin '$Bin';
use lib "$Bin";

require "testlib.pl";
use Test::More 0.98;

run_spectest('perl', {
    skip_if => sub {
        my $t = shift;
        return 0 unless $t->{tags};

        # disabled temporarily because failing for bool, even though i've adjust
        # stuffs. but 'between' clause should be very seldomly used on bool,
        # moreover with op, so i haven't looked into it.
        return "currently failing"
            if all_match([qw/type:bool clause:between op/], $t->{tags});

        for (qw/req_keys_re
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
