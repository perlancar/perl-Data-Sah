package Data::Sah::Lang;

use 5.010;
use strict;
use warnings;

# AUTHORITY
# DATE
# DIST
# VERSION

our @ISA    = qw(Exporter);
our @EXPORT = qw(add_translations);

sub add_translations {
    my %args = @_;

    # XXX check caller package and determine language, fill translations in
    # %Data::Sah::Lang::<lang>::translations
}

1;
# ABSTRACT: Language routines

=for Pod::Coverage add_translations
