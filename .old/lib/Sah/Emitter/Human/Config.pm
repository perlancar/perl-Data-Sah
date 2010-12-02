package Data::Schema::Emitter::Human::Config;
# ABSTRACT: Configuration for human text emitter of Data::Schema

=head1 SYNOPSIS

    # getting configuration
    if ($emitter->config->format eq 'html') { ... }

    # setting configuration
    $emitter->config->as('document');

=head1 DESCRIPTION

See also L<Data::Schema::Emitter::Base::Config>, from which this class is
derived.

=cut

use Any::Moose;
extends 'Data::Schema::Emitter::Base::Config';

=head1 ATTRIBUTES

=head2 lang => SCALAR

Default is taken from LANG environment variable, with 'en' (English) as the
fallback. Set the default language to choose when displaying error messages, etc.

=cut

has lang => (is => 'rw', default => sub { $ENV{LANG} =~ /^(\w\w)/ ? $1 : 'en' });

=head2 format => SCALAR

Output format. Default is 'text'. Other choices include 'html' and 'raw' (markup
similar to HTML, only useful for debugging).

=cut

has format => (is => 'rw', default => 'text');

=head2 as => SCALAR

Choices: 'phrase', 'sentence', 'paragraph', 'document'. Default is 'phrase'. This
instructs human() on how to generate the human text. 'phrase' will make it as one
long phrase where everything is separated by commas and semicolon. 'sentence' is
the same, but will capitalize the first letter and add a final stop. 'paragraph'
will render the text as one paragraph of sentences. And 'document' will render
the text as a document containing a series of paragraphs.

=cut

has as => (is => 'rw', default => 'phrase');

=head2 text_right_margin => SCALAR

Only relevant for 'text' format. Used for text wrapping. Default is 0, meaning
there is no text wrapping. Text wrapping is done by L<Text::Wrap>.

=cut

has text_right_margin => (is => 'rw', default => 0);

=head2 prog_emitter_name => NAME

What emitter is used to generate programming language. Defaults to 'Perl'.

This will affect dumping format in stringf(), as stringf() calls
$ds->emitters->{$prog_emitter}->dump().

=cut

has prog_emitter_name => (is => 'rw', default => 'Perl');

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
