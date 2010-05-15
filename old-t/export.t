#!perl -T

use lib './t';
use lib './t/lib';
use warnings;
use Test::More tests => 10;
use Test::Exception;

eval "package I1; require Data::Schema; import Data::Schema qw/Foo/; package main;";
ok($@, 'import: unknown');

#plugin

package IP1; require Data::Schema; import Data::Schema qw/Plugin::LoadSchema::YAMLFile Plugin::LoadSchema::Hash/; our $ds = new Data::Schema; package main;
is(scalar(@{ $IP1::ds->plugins }), 2, 'import plugin 1');

package IP2; require Data::Schema; import Data::Schema qw//; our $ds = new Data::Schema; package main;
is(scalar(@{ $IP2::ds->plugins }), 0, 'import plugin 2');

eval "package IP3; require Data::Schema; import Data::Schema qw/Plugin::Foo/; package main;";
ok($@, 'import plugin: unknown');

# type
package IT1; require Data::Schema; import Data::Schema qw/Type::MyType1/; our $ds = new Data::Schema; package main;
ok($IT1::ds->type_handlers->{mytype1}, 'import type 1');
ok(!$IP2::ds->type_handlers->{mytype1}, 'import type 2');

# schema
package IS1; require Data::Schema; import Data::Schema qw/Schema::Schema/; our $ds = new Data::Schema; package main;
ok($IS1::ds->type_handlers->{schema}, 'import schema 1');
ok(!$IP2::ds->type_handlers->{schema}, 'import schema 2');

# filter
#my $num_default_filters = 20;
#is(scalar(@{ $IP2::ds->filters }), $num_default_filters, 'import filter 1');

package IF1; require Data::Schema; import Data::Schema qw/Filters::MyFilter1/; our $ds = new Data::Schema; package main;
#is(scalar(@{ $IF1::ds->filters }), $num_default_filters+1, 'import filter 2');
ok( $IF1::ds->filters->{alay}, 'import filter 2a');
ok(!$IP2::ds->filters->{alay}, 'import filter 2b');
#valid("saya dah pergi", [str => {prefilters=>['alay'], is=>"s4ii4 d4h p3rgee"}], 'import filter 2c', $IF1::ds);
