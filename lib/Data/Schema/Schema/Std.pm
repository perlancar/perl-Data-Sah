package Data::Schema::Schema::Std;
# ABSTRACT: Some standard DS schemas

=head1 DESCRIPTION

This module contains several schemas which are common. They are loaded
by default: regex/regexp.

=cut

use 5.010;
use strict;
use warnings;

sub schemas {
    state $a = {
        'regex'  => [str => {isa_regex=>1}],
        'regexp' => [str => {isa_regex=>1}],
    };
}

1;
