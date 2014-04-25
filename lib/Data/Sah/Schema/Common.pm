package Data::Sah::Schema::Common;

use 5.010;
use strict;
use warnings;

# VERSION

sub schemas {
    {

        regex => [str => {
            name      => 'regex',
            summary   => 'Regular expression string',
            isa_regex => 1,
        }],

        pos_int => [int => {
            name      => 'pos_int',
            summary   => 'Positive integer',
            min       => 0,
        }],

        neg_int => [int => {
            name      => 'neg_int',
            summary   => 'Positive integer',
            max       => 0,
        }],

        nat_num => [int => {
            name        => 'nat_num',
            summary     => 'Natural number',
            description => <<_,

Natural numbers are whole numbers starting from 1, used for counting ('there are
6 coins on the table') and ordering ('this is the 3rd largest city in the
country').

_
            min         => 1,
        }],

    };
}

1;
# ABSTRACT: Collection of common schemas

=for Pod::Coverage ^(schemas)$
