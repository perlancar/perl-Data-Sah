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
text.


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
