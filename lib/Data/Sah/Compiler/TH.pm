package Data::Sah::Compiler::TH;

use Moo;

# VERSION

# reference to compiler object
has compiler => (is => 'rw');

sub clause_v {
    my ($self, $cd) = @_;
    $self->compiler->_ignore_clause($cd);
}

sub clause_default_lang {
    my ($self, $cd) = @_;
    $self->compiler->_ignore_clause($cd);
}

1;
# ABSTRACT: Base class for type handlers

=for Pod::Coverage ^(compiler|clause_.+)$

=cut
