package Data::Sah::Compiler::BaseCompiler::TH::BaseTH;

use Class::Inspector;
use Moo;

sub list_clauses {
    my ($self) = @_;
    my @res;

    my $methods = Class::Inspector->methods(ref($self));
    for (@$methods) {
        push @res, $1 if /^clause_(.+)/;
    }
    \@res;
}

sub is_clause {
    my ($self, $name) = @_;
    $self->can("clause_$name") ? 1 : 0;
}

sub list_names_of_clause {
    my ($self, $name) = @_;
    my $re = qr/^clausealias_(.+?)__(.+)$/;
    my @m = grep { /$re/ } @{ Class::Inspector->methods(ref($self)) };
    my $canon;
    for (@m) {
        /$re/;
        if ($1 eq $name || $2 eq $name) { $canon = $1; last }
    }
    return [] unless $canon;
    my @res = ($canon);
    for (@m) {
        /$re/;
        push @res, $2 if $1 eq $canon;
    }
    \@res;
}

1;
__END__
# ABSTRACT: Base class for type handlers

=head1 DESCRIPTION

This is the base class for type handlers.


=head1 ATTRIBUTES


=head1 METHODS

=head2 $th->list_clauses() => ARRAYREF

Return list of known type clause names. Basically what it does is list methods
matching /clause_(.+)/.

=head2 $th->is_clause($name) => BOOL

Return true if $name is a valid type clause name.

=head2 $th->list_names_of_clause($name) => ARRAYREF

Return a list of names and alias namees for clause named $name. The first
element is the canonical name and the rest are aliases. If [$name] is returned,
it means the clause doesn't have any aliases.

=cut
