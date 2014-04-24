package Data::Sah::Type::date;

use Moo::Role;
use Data::Sah::Util::Role 'has_clause';
with 'Data::Sah::Type::BaseType';
with 'Data::Sah::Type::Comparable';
with 'Data::Sah::Type::Sortable';
with 'Data::Sah::Type::HasElems';

# VERSION
# DATE

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
