package Data::Sah::Type::any;

use Moo::Role;
use Data::Sah::Util 'has_clause';
##with 'Data::Sah::Type::BaseType';

# VERSION

has_clause 'of', arg => ['array*' => {of=>'schema*'}];

1;
# ABSTRACT: any type
