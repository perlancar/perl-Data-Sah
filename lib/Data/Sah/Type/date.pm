package Data::Sah::Type::date;

# DATE
# VERSION

use Data::Sah::Util::Role 'has_clause';
use Role::Tiny;
use Role::Tiny::With;

with 'Data::Sah::Type::BaseType';
with 'Data::Sah::Type::Comparable';
with 'Data::Sah::Type::Sortable';

# XXX prop: year
# XXX prop: quarter (1-4)
# XXX prop: month
# XXX prop: day
# XXX prop: day_of_month
# XXX prop: hour
# XXX prop: minute
# XXX prop: second
# XXX prop: millisecond
# XXX prop: microsecond
# XXX prop: nanosecond
# XXX prop: day_of_week
# XXX prop: day_of_quarter
# XXX prop: day_of_year
# XXX prop: week_of_month
# XXX prop: week_of_year
# XXX prop: date?
# XXX prop: time?
# XXX prop: time_zone_long_name
# XXX prop: time_zone_offset
# XXX prop: is_leap_year

1;
# ABSTRACT: date type

=for Pod::Coverage ^(clause_.+|clausemeta_.+)$
