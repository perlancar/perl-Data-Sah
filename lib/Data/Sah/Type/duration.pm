package Data::Sah::Type::duration;

use strict;

use Data::Sah::Util::Role 'has_clause';
use Role::Tiny;
use Role::Tiny::With;

with 'Data::Sah::Type::BaseType';
with 'Data::Sah::Type::Comparable';
with 'Data::Sah::Type::Sortable';

# XXX prop: ...

# AUTHORITY
# DATE
# DIST
# VERSION

1;
# ABSTRACT: date/time duration type

=for Pod::Coverage ^(clause_.+|clausemeta_.+)$
