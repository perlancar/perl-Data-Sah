package Data::Sah::Compiler::TextResultRole;

# DATE
# VERSION

use 5.010;
use Moo::Role;

use String::Indent ();

# can be changed to tab, for example
has indent_character => (is => 'rw', default => sub {''});

sub add_result {
    my ($self, $cd, @args) = @_;

    $cd->{result} //= [];
    push @{ $cd->{result} }, $self->indent($cd, join("", @args));
    $self;
}

sub indent {
    my ($self, $cd, $str) = @_;
    String::Indent::indent(
        $self->indent_character x $cd->{indent_level},
        $str,
    );
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

=head1 ATTRIBUTES

=head2 indent_character => STR


=head1 METHODS

=head2 $c->add_result($cd, @arg)

Append result to C<< $cd->{result} >>. Will use C<< $cd->{indent_level} >> to
indent the line. Used by compiler; users normally do not need this.

=head2 $c->inc_indent($cd)

Increase indent level. This is done by increasing C<< $cd->{indent_level} >> by
1.

=head2 $c->dec_indent($cd)

Decrease indent level. This is done by decreasing C<< $cd->{indent_level} >> by
1.

=head2 $c->indent_str($cd)

Shortcut for C<< $c->indent_character x $cd->{indent_level} >>.

=head2 $c->indent($cd, $str) => STR

Indent each line in $str with indent_str and return the result.

=cut
