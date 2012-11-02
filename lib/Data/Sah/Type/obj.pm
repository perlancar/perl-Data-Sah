package Data::Sah::Type::obj;

use Moo::Role;
use Data::Sah::Util 'has_clause';
with 'Data::Sah::Type::BaseType';

# VERSION

has_clause 'can',
    tags       => ['constraint'],
    arg        => 'str*', # XXX perl_method_name
    allow_expr => 1,
    ;
has_clause 'isa',
    tags       => ['constraint'],
    arg        => 'str*', # XXX perl_class_name
    allow_expr => 1,
    ;

1;
# ABSTRACT: obj type

