package Data::Sah::Easy;

use 5.010;
use strict;
use warnings;

use Data::Sah;

1;
# ABSTRACT: Simple interface to Data::Sah

=head1 SYNOPSIS

 use Data::Sah::Easy qw(
     validate_schema
     normalize_schema
     gen_validator
     schema2perl
     schema2human
     schema2js
 );

 my $s = ['int*', min=>1, max=>10];

 # check if schema is valid, returns a Data::Sah::Result object
 my $res = validate_schema($s);

 # normalize schema into hash form
 my $normalized = normalize_schema($s);

 # generate validator
 my $vdr = gen_validator($s);

 # validate your data using the generated validator
 $res = $vdr->(5);     # valid
 $res = $vdr->(11);    # invalid
 $res = $vdr->(undef); # invalid
 $res = $vdr->("x");   # invalid

 # peek the Perl source code generated
 my $perl = schema2perl($s);

 # generate human text description from schema
 my $txt;
 $txt = schema2human($s, {lang=>'en_US'}); # integer, value between 1 and 10
 $txt = schema2human($s, {lang=>'id_ID'}); # bil bulat, nilai antara 1 dan 10

 # generate Javascript code (XXX details)
 my $res = schema2js($s);


=head1 DESCRIPTION

This module provides more straightforward functional interface to L<Data::Sah>.
For full power and configurability you'll still need to use Data::Sah compilers
directly.


=head1 FUNCTIONS

None are exported, but they are exportable.


=head1 SEE ALSO

L<Data::Sah>

=cut

