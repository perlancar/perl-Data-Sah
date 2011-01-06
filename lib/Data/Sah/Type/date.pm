package Data::Sah::Type::date;
# ABSTRACT: Specification for date type

=head1 DESCRIPTION

This is the specification for 'date' type. It follows loosely from the wonderful
L<DateTime> Perl module for the implementation. The Perl emitter uses the
DateTime module. Some other languages might lack partial implementation.

A valid 'date' value must be either a formatted string, or an instance of some
DateTime object (depends on emitter).

=cut

use 5.010;
use Any::Moose '::Role';
use Data::Sah::Util 'clause';
with
    'Data::Sah::Type::Base',
    'Data::Sah::Type::Comparable',
    'Data::Sah::Type::Sortable',
    'Data::Sah::Type::HasElems';

sub _indexes0 {
    my ($self, $data) = @_;
    state $e = [qw/year month mon day doy_of_month mday hour minute min second sec
                   millisecond microsecond nanosecond
                   day_of_quarter doq day_of_week wday dow day_of_year
                   week_number week_of_month
                   ymd date hms time
                   iso8601
                   is_leap_year
                   time_zone_long_name offset
                  /];
}

=head1 CLAUSES

date assumes the roles L<Data::Sah::Type::Base>, L<Data::Sah::Type::Comparable>,
L<Data::Sah::Type::Sortable>, L<Data::Sah::Type::HasElement>. Consult the documentation of
those base type and role(s) to see what type clauses are available.

Currently there is no extra clauses.

Elements of 'date' value are (they mostly translate directly from L<DateTime>
methods):

=over 4

=item * year

=item * month

1-12, also C<mon>

=item * day

1-31, also C<day_of_month>, C<mday>

=item * hour

0-23

=item * minute

0-59, also C<min>

=item * second

0-61, also C<sec>

=item * millisecond

=item * microsecond

=item * nanosecond

=item * day_of_quarter

1-..., also C<doq>

=item * day_of_week

1-7, Monday is 1, also C<wday>, C<dow>

=item * day_of_year

1-366, also C<doy>

=item * iso8601

e.g. 2010-01-22T12:41:30

=item * is_leap_year

0 or 1

=item * quarter

1-4

=item * week_number

Week of the year, 1-53.

=item * week_of_month

Week of the month, 0-5.

=item * time_zone_long_name

e.g. Asia/Jakarta

=item * offset

Offset from UTC, in seconds.

=item * ymd

e.g. 2010-01-22, also C<date>

=item * hms

e.g. 12:40:59, also C<time>

=back

You can validate these elements individually using C<elements>.

Example:

 # date with even year, but odd month, e.g. 2010-01-xx
 [date => {elements=>{
     year=>[int=>{  divisible_by=>2}],
     mon =>[int=>{indivisible_by=>2}],
 }}]

=cut

no Any::Moose;
1;
