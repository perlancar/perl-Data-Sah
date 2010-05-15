package Data::Schema::Emitter::ProgBase::Config;
# ABSTRACT: Base class for programming language emitters' config

use Any::Moose;
extends 'Data::Schema::Emitter::Base::Config';

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

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
