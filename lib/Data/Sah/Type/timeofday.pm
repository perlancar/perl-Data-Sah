package Data::Sah::Type::timeofday;

use strict;

use Data::Sah::Util::Role 'has_clause';
use Role::Tiny;
use Role::Tiny::With;

with 'Data::Sah::Type::BaseType';
with 'Data::Sah::Type::Comparable';
with 'Data::Sah::Type::Sortable';

# AUTHORITY
# DATE
# DIST
# VERSION

1;
# ABSTRACT: timeofday type

=for Pod::Coverage ^(clause_.+|clausemeta_.+)$
