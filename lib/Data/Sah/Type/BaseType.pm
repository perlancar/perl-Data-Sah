package Data::Sah::Type::BaseType;

# AUTHORITY
# DATE
# DIST
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

our $sch_filter_elem = ['any', {of=>[
    ['str', {req=>1}],
    ['array', {req=>1, len=>2, elems=>[ ['str',{req=>1}], ['hash',{req=>1}] ]}],
]}];

requires 'handle_type';

has_clause 'v',
    v => 2,
    prio   => 0,
    tags   => ['meta', 'defhash'],
    schema => ['float'=>{req=>1, is=>1}],
    ;

has_clause 'defhash_v',
    v => 2,
    prio   => 0,
    tags   => ['meta', 'defhash'],
    schema => ['float'=>{req=>1, is=>1}],
    ;

has_clause 'schema_v',
    v => 2,
    prio   => 0,
    tags   => ['meta'],
    schema => ['float'=>{req=>1}],
    ;

has_clause 'base_v',
    v => 2,
    prio   => 0,
    tags   => ['meta'],
    schema => ['float'=>{req=>1}],
    ;

has_clause 'ok',
    v => 2,
    tags       => ['constraint'],
    prio       => 1,
    schema     => ['any', {}],
    allow_expr => 1,
    ;
has_clause 'default',
    v => 2,
    prio       => 1,
    tags       => ['default'],
    schema     => ['any', {}],
    allow_expr => 1,
    attrs      => {
        temp => {
            schema     => [bool => {default=>0}],
            allow_expr => 0,
        },
    },
    ;
has_clause 'prefilters',
    v => 2,
    tags       => ['filter'],
    prio       => 10,
    schema      => ['array' => {of=>$sch_filter_elem}],
    attrs      => {
        temp => {
        },
    }
    ;
has_clause 'default_lang',
    v => 2,
    tags       => ['meta', 'defhash'],
    prio       => 2,
    schema     => ['str'=>{req=>1, default=>'en_US'}],
    ;
has_clause 'name',
    v => 2,
    tags       => ['meta', 'defhash'],
    prio       => 2,
    schema     => ['str', {req=>1}],
    ;
has_clause 'summary',
    v => 2,
    prio       => 2,
    tags       => ['meta', 'defhash'],
    schema     => ['str', {req=>1}],
    ;
has_clause 'description',
    v => 2,
    tags       => ['meta', 'defhash'],
    prio       => 2,
    schema     => ['str', {req=>1}],
    ;
has_clause 'tags',
    v => 2,
    tags       => ['meta', 'defhash'],
    prio       => 2,
    schema     => ['array', {of=>['str', {req=>1}, {}]}],
    ;
has_clause 'req',
    v => 2,
    tags       => ['constraint'],
    prio       => 3,
    schema     => ['bool', {}],
    allow_expr => 1,
    ;
has_clause 'forbidden',
    v => 2,
    tags       => ['constraint'],
    prio       => 3,
    schema     => ['bool', {}],
    allow_expr => 1,
    ;
has_clause 'if',
    v => 2,
    tags       => ['constraint'],
    prio       => 50,
    schema     => ['array', {}], # XXX elems: [str|array|hash, str|array|hash, [ str|array|hash ]]
    allow_expr => 0,
;

#has_clause 'each', tags=>['constraint'];

#has_clause 'check_each', tags=>['constraint'];

#has_clause 'exists', tags=>['constraint'];

#has_clause 'check_exists', tags=>['constraint'];

#has_clause 'check', schema=>['sah::expr',{req=>1},{}], tags=>['constraint'];

has_clause 'clause',
    v => 2,
    tags       => ['constraint'],
    prio       => 50,
    schema     => ['array' => {req=>1, len=>2, elems => [
        ['sah::clname', {req=>1}],
        ['any', {}],
    ]}],
    ;
has_clause 'clset',
    v => 2,
    prio   => 50,
    tags   => ['constraint'],
    schema => ['sah::clset', {req=>1}],
    ;
has_clause 'postfilters',
    v => 2,
    tags       => ['filter'],
    prio       => 90,
    schema     => ['array' => {req=>1, of=>$sch_filter_elem}],
    attrs      => {
    }
    ;
has_clause 'examples',
    v => 2,
    tags       => ['meta'],
    prio       => 99,
    schema     => ['array', {of=>['any', {}]}], # XXX non-hash or defhash with 'value' property specified
    ;
has_clause 'invalid_examples',
    v => 2,
    tags       => ['meta'],
    prio       => 99,
    schema     => ['array', {of=>['any', {}]}], # XXX non-hash or defhash with 'value' property specified
    ;

1;
# ABSTRACT: Base type

=for Pod::Coverage ^(clause_.+|clausemeta_.+)$
