package Data::Sah::Emitter::ProgBase::Config;
# ABSTRACT: Base class for programming language emitters' config

=head1 DESCRIPTION

See also L<Data::Sah::Emitter::Base::Config>, from which this class is
derived.

=cut

use Any::Moose;
extends 'Sah::Emitter::Base::Config';

=head1 ATTRIBUTES

=head2 namespace => SCALAR

Namespace to put functions and variables in. Each programming language
has its own default.

=cut

has namespace => (is => 'rw');

=head2 sub_prefix => SCALAR

Prefix to add to function/subroutine names. Each programming language
has its own default (e.g. PHP might need this due to lack of
namespaces).

=cut

has sub_prefix => (is => 'rw');

=head2 indent => SCALAR

Number of spaces to use for each increase of indentation level. Each
programming language has its own default (e.g. Perl defaults to 4, PHP
and Ruby to 2, etc.)

=cut

has indent => (is => 'rw');

=head2 comment_style => SCALAR

Style of comment, either 'shell' ('#', which is used by Perl, PHP,
Python, as well as Ruby) or 'c++' ('//', which is used by Javascript).

=cut

has comment_style => (is => 'rw');

=head2 report_all_errors => BOOL

Whether to report all errors or not. Default is true. If set to 0, emitter will
produce validator code that only returns a single error string (or undef if there
is no validation error) and no warnings. This produces faster and simpler code,
because there is no need to collect and track all errors, just one.

=cut

has report_all_errors => (is => 'rw', default => 1);

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
