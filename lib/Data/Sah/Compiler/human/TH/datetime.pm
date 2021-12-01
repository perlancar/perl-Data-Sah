package Data::Sah::Compiler::human::TH::datetime;

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Mo qw(build default);
use Role::Tiny::With;

extends 'Data::Sah::Compiler::human::TH::date';

# AUTHORITY
# DATE
# DIST
# VERSION

sub name { "datetime" }

sub handle_type {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    $c->add_ccl($cd, {type=>'noun', fmt => ["datetime", "datetimes"]});
}

1;
# ABSTRACT: perl's type handler for type "datetime"

=for Pod::Coverage ^(name|clause_.+|superclause_.+|before_.+|after_.+)$
