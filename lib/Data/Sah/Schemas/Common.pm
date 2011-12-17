package Data::Sah::Schemas::Common;

use 5.010;
use strict;
use warnings;

sub schemas {
    {

        regex => [str => {
            name      => 'regex',
            summary   => 'Regular expression string',
            isa_regex => 1,
        }],

         => [
        ],
    };
}

1;
