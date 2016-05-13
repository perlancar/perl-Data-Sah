package Data::Sah::Compiler::perl::Coerce;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

sub should_coerce {
    # my ($self, $cd) = @_;
    1;
}

1;
# ABSTRACT: Base class for perl coerce handler

=for Pod::Coverage ^()$

=head1 DESCRIPTION

See L<Data::Sah::Manual::Developer/"Coercion (perl)">.


=head1 METHODS

=head2 CLASS->should_coerce($cd) => bool

By default returns 1. Can be overriden to do optional coercion, for example if
you want to coerce array of integers from a string containing comma-separated
numbers e.g. C<"1,5,33">, then you can make a coerce handler
C<Data::Sah::Compiler::perl::Coerce::array::str_comma_sep_int> which contains
something like:

 package Data::Sah::Compiler::perl::Coerce::array::str_comma_sep_int;

 use parent 'Data::Sah::Compiler::perl::Coerce';

 sub should_coerce {
     my ($self, $cd) = @_;

     $sch = $cd->{nschema};
     return 1 if $sch->[1]{of} && $sch->[1]{of}[0] eq 'int';
     0;
 }

 ...

This means that not all array schemas should be added the coercion rule.

=head2 CLASS->coerce($cd [, $data_term ]) => $coerce_cd

Generate code for coercion. Accepts C<$data_term>, which if unspecified will
default to C<< $cd->{args}{data_term} >>.

=cut
