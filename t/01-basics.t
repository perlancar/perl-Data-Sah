#!perl -T

use 5.010;
use strict;
use warnings;

use Data::Sah;
use Test::More 0.98;

is_deeply(Data::Sah::normalize_schema("a*"), [a => {req=>1}],
          "normalize_schema() can be used as function");

done_testing();
