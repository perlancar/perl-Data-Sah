package Data::Sah::Type::all;

use Moo::Role;
use Data::Sah::Util::Role 'has_clause';
with 'Data::Sah::Type::BaseType';

# VERSION

has_clause 'of',
    tags       => ['constraint'],
    arg        => ['array*' => {min_len=>1, each_elem => 'schema*'}],
    allow_expr => 0,
    ;

1;
# ABSTRACT: all type

=for Pod::Coverage ^(clause_.+|clausemeta_.+)$
                                                                                                                                          