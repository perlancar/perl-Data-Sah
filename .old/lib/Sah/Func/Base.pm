package Data::Schema::Spec::v10::Func::Base;
# ABSTRACT: Some traits for functions

=head1 DESCRIPTION

=cut

##use Any::Moose '::Role';

=head1 METHODS

=cut

=head2 list_funcs() -> ARRAY

Return list of known functions.

=cut

sub list_attrs {
    my ($self) = @_;
    my @res;
    for ($self->meta->get_method_list) {
        push @res, $1 if /^func_(.+)/;
    }
    @res;
}

=head2 is_func($name) -> BOOL

Return true if $name is a valid function name.

=cut

sub is_func {
    my ($self, $name) = @_;
    $self->can("func_$name") ? 1 : 0;
}

=head2 get_func_aliases($name) -> ARRAY

Return a list of function aliases (including itself). The first element is the
canonical name.

=cut

sub get_func_aliases {
    my ($self, $name) = @_;
    my $re = qr/^funcalias_(.+?)__(.+)$/;
    my @m = grep { /$re/ } $self->meta->get_method_list;
    my $canon;
    for (@m) {
        /$re/;
        if ($1 eq $name || $2 eq $name) { $canon = $1; last }
    }
    return () unless $canon;
    my @res = ($canon);
    for (@m) {
        /$re/;
        push @res, $2 if $1 eq $canon;
    }
    @res;
}

##no Any::Moose;
1;
