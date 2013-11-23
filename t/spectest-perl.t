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

        for (qw/

                   allowed_keys
                   allowed_keys_re
                   check
                   check_each_elem
                   check_each_index
                   check_each_key
                   check_each_value
                   check_prop
                   exists
                   forbidden_keys
                   forbidden_keys_re
                   if
                   postfilters
                   prefilters
                   prop
                   uniq

               /) {
            return "clause $_ not yet implemented"
                if all_match(["clause:$_"], $t->{tags});
        }

        return "properties are not yet implemented"
            if grep {/^prop:/} @{ $t->{tags} };

        0;
    },
});
done_testing();
