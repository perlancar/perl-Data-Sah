package Data::Sah::Compiler::human;

use 5.010;
use Moo;
extends 'Data::Sah::Compiler';
use Log::Any qw($log);

# VERSION

sub name { "human" }

sub check_compile_args {
    my ($self, $args) = @_;

    $self->SUPER::check_compile_args($args);

    # XXX format? html/text/markdown
    #$args->{foo} //= 0;
}

sub before_compile {
    my ($self, $cd) = @_;
    #get language handle
}

sub before_all_clauses {
    my ($self, $cd) = @_;
    # get language handle
}

sub after_all_clauses {
    my ($self, $cd) = @_;

    # join ccls into sentence/paragraph/whatever

    #$cd->{result} = $self->join_ccls($cd, $cd->{ccls}, {err_msg => ''});
}

1;
# ABSTRACT: Compile Sah schema to human language

=head1 SYNOPSIS


=head1 DESCRIPTION

This class is derived from L<Data::Sah::Compiler>. It generates human language
text

compilers which compile schemas into code (usually a validator) in programming
language targets, like L<Data::Sah::Compiler::perl> and
L<Data::Sah::Compiler::js>. The generated validator code by the compiler will be
able to validate data according to the source schema, usually without requiring
Data::Sah anymore.

Aside from Perl and JavaScript, this base class is also suitable for generating
validators in other procedural languages, like PHP, Python, and Ruby. See CPAN
if compilers for those languages exist.

Compilers using this base class are usually flexible in the kind of code they
produce:

=over 4

=item * configurable validator return type

Can generate validator that returns a simple bool result, str, or full data
structure.

=item * configurable data term

For flexibility in combining the validator code with other code, e.g. in sub
wrapper (one such application is in L<Perinci::Sub::Wrapper>).

=back

Planned future features include:

=over 4

=item * generating other kinds of code (aside from validators)

Perhaps data compliance measurer, data transformer, or whatever.

=back


=head1 ATTRIBUTES


=head1 METHODS

=head2 new() => OBJ

=head2 $c->compile(%args) => RESULT

Aside from base class' arguments, this class supports these arguments (suffix
C<*> denotes required argument):

=over 4

=item *

=back

=head3 Compilation data

This subclass adds the following compilation data (C<$cd>).

Keys which contain compilation state:

=over 4

=back

Keys which contain compilation result:

=over 4

=back

=cut
