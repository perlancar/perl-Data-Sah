#!perl -T

use lib './t'; do 'testlib.pm';
use strict;
use warnings;
use Test::More tests => 2*4;
use Test::Exception;
use Data::Schema;

my $ds = Data::Schema->new();
$ds->config->prefilters(['ltrim']);
validate_is(' foo ', 'str', 'foo ', 'prefilters 1', $ds);
validate_is(' foo ', [str=>{prefilters=>['rtrim']}], 'foo', 'prefilters 2', $ds);
