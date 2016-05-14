package Data::Sah::Type::BaseType;

# DATE
# VERSION

# why name it BaseType instead of Base? because I'm sick of having 5 files named
# Base.pm in my editor (there would be Type::Base and the various
# Compiler::*::Type::Base).

use 5.010;
use strict;
use warnings;

use Data::Sah::Util::Role 'has_clause';
use Role::Tiny;
#use Sah::Schema::Common;
#use Sah::Schema::Sah;

requires 'handle_type';

has_clause 'v',
    prio => 0,
    tags => ['meta', 'defhash'],
    arg  => ['float'=>{req=>1, is=>1}, {}],
    ;

has_clause 'defhash_v',
    prio => 0,
    tags => ['meta', 'defhash'],
    arg  => ['float'=>{req=>1, is=>1}, {}],
    ;

has_clause 'schema_v',
    prio => 0,
    tags => ['meta'],
    arg  => ['float'=>{req=>1}, {}],
    ;

has_clause 'base_v',
    prio => 0,
    tags => ['meta'],
    arg  => ['float'=>{req=>1}, {}],
    ;

has_clause 'ok',
    tags       => ['constraint'],
    prio       => 1,
    arg        => ['any', {}, {}],
    allow_expr => 1,
    ;
has_clause 'default',
    prio       => 1,
    tags       => [],
    arg        => ['any', {}, {}],
    allow_expr => 1,
    attrs      => {
        temp => {
            arg        => [bool => {default=>0}, {}],
            allow_expr => 0,
        },
    },
    ;
# has_clause 'prefilters',
#     tags       => ['filter'],
#     prio       => 10,
#     arg        => ['array' => {of=>['sah::expr', {req=>1}, {}]}, {}],
#     attrs      => {
#         temp => {
#         },
#     }
#     ;
has_clause 'default_lang',
    tags       => ['meta', 'defhash'],
    prio       => 2,
    arg        => ['str'=>{req=>1, default=>'en_US'}, {}],
    ;
has_clause 'name',
    tags       => ['meta', 'defhash'],
    prio       => 2,
    arg        => ['str', {req=>1}, {}],
    ;
has_clause 'summary',
    prio       => 2,
    tags       => ['meta', 'defhash'],
    arg        => ['str', {req=>1}, {}],
    ;
has_clause 'description',
    tags       => ['meta', 'defhash'],
    prio       => 2,
    arg        => ['str', {req=>1}, {}],
    ;
has_clause 'tags',
    tags       => ['meta', 'defhash'],
    prio       => 2,
    arg        => ['array', {of=>['str', {req=>1}, {}]}, {}],
    ;
has_clause 'req',
    tags       => ['constraint'],
    prio       => 3,
    arg        => ['bool', {}, {}],
    allow_expr => 1,
    ;
has_clause 'forbidden',
    tags       => ['constraint'],
    prio       => 3,
    arg        => ['bool', {}, {}],
    allow_expr => 1,
    ;
#has_clause 'if', tags=>['constraint'];

#has_clause 'each', tags=>['constraint'];

#has_clause 'check_each', tags=>['constraint'];

#has_clause 'exists', tags=>['constraint'];

#has_clause 'check_exists', tags=>['constraint'];

#has_clause 'check', arg=>'expr*', tags=>['constraint'];

has_clause 'clause',
    tags       => ['constraint'],
    prio       => 50,
    arg        => ['array' => {req=>1, len=>2, elems => [
        ['sah::clname', {req=>1}, {}],
        ['any', {}, {}],
    ]}, {}],
has_clause 'clset',
    prio => 50,
    tags => ['constraint'],
    arg  => ['sah::clset', {req=>1}, {}],
    ;
# has_clause 'postfilters',
#     tags       => ['filter'],
#     prio       => 90,
#     arg        => ['array' => {req=>1, of=>['sah::expr', {req=>1}, {}]}, {}],
#     attrs      => {
#         temp => {
#         },
#     }
#     ;

1;
# ABSTRACT: Base type

=for Pod::Coverage ^(clause_.+|clausemeta_.+)$
