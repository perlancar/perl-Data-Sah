package Data::Sah::Simple;

use 5.010;
use strict;
use warnings;

use Data::Sah;

# VERSION

1;
# ABSTRACT: Simple interface to Data::Sah

=head1 SYNOPSIS

 use Data::Sah::Simple qw(
     normalize_schema
     validate_schema
     gen_validator
 );

 my $s = ['int*', min=>1, max=>10];

 # check if schema is valid
 my $res = validate_schema($s);

 # normalize schema
 my $ns = normalize_schema($s);

 # generate validator
 my $vdr = gen_validator($s, \%opts);

 # validate your data using the generated validator
 $res = $vdr->(5);     # valid
 $res = $vdr->(11);    # invalid
 $res = $vdr->(undef); # invalid
 $res = $vdr->("x");   # invalid


=head1 DESCRIPTION

This module provides more straightforward functional interface to L<Data::Sah>.
For full power and configurability you'll need to use Data::Sah compilers
directly.


=head1 FUNCTIONS

None are exported, but they are exportable.


=head1 SEE ALSO

L<Data::Sah>

=cut
