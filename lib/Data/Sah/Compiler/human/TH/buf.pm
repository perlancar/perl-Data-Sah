package Data::Sah::Compiler::human::TH::buf;

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Mo qw(build default);
use Role::Tiny::With;

extends 'Data::Sah::Compiler::human::TH::str';

# AUTHORITY
# DATE
# DIST
# VERSION

sub name { "buffer" }

sub handle_type {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    $c->add_ccl($cd, {
        fmt   => ["buffer", "buffers"],
        type  => 'noun',
    });
}

1;
# ABSTRACT: perl's type handler for type "buf"

=for Pod::Coverage ^(name|clause_.+|superclause_.+|before_.+|after_.+)$
