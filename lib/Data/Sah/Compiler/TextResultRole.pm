package Data::Sah::Compiler::TextResultRole;

use 5.010;
use Moo::Role;

# VERSION

# can be changed to tab, for example
has indent_character => (is => 'rw', default => sub {''});

sub line {
    my ($self, $cd, @args) = @_;

    $cd->{result} //= [];
    push @{ $cd->{result} }, join(
        "", $self->indent_character x $cd->{indent_level},
        @args);
    $self;
}

sub inc_indent {
    my ($self, $cd) = @_;
    $cd->{indent_level}++;
}

sub dec_indent {
    my ($self, $cd) = @_;
    $cd->{indent_level}--;
}

sub indent_str {
    my ($self, $cd) = @_;
    $self->indent_character x $cd->{indent_level};
}

1;
# ABSTRACT: Role for compilers that produce text result (array of lines)

=head1 METHODS

=head2 $c->line($cd, @arg)

Append a line to C<< $cd->{result} >>. Will use C<< $cd->{indent_level} >> to
indent the line. Used by compiler; users normally do not need this. Example:

 $c->line($cd, 'this is a line', ' of ', 'code');

When C<< $cd->{indent_level} >> is 2 and C<< $cd->{args}{indent_width} >> is 2,
this line will be added with 4-spaces indent:

 this is a line of code

=head2 $c->inc_indent($cd)

Increase indent level. This is done by increasing C<< $cd->{indent_level} >> by
1.

=head2 $c->dec_indent($cd)

Decrease indent level. This is done by decreasing C<< $cd->{indent_level} >> by
1.

=head2 $c->indent_str($cd)

Shortcut for C<< $c->indent_character x $cd->{indent_level} >>.

=cut
