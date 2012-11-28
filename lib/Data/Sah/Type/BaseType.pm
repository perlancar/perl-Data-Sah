package Data::Sah::Type::BaseType;
# why name it BaseType instead of Base? because I'm sick of having 5 files named
# Base.pm in my editor (there would be Type::Base and the various
# Compiler::*::Type::Base).

use Moo::Role;
#use Data::Sah::Schema::Common;
#use Data::Sah::Schema::sah;
use Data::Sah::Util::Role 'has_clause';

# VERSION

requires 'handle_type';

has_clause 'v',
    prio=>0, tags=>['meta', 'defhash'],
    arg=>['int*'=>{is=>1}];

#has_clause 'defhash_v';

#has_clause 'schema_v';

#has_clause 'base_v';

has_clause 'default',
    prio       => 1,
    tags       => [],
    arg        => 'any',
    allow_expr => 1,
    attrs      => {
        temp => {
            arg        => [bool => default=>0],
            allow_expr => 0,
        },
    },
    ;
# has_clause 'prefilters',
#     tags       => ['filter'],
#     prio       => 10,
#     arg        => ['array*' => of=>'expr*'],
#     attrs      => {
#         temp => {
#         },
#     }
#     ;
has_clause 'default_lang',
    prio=>2, tags=>['meta', 'defhash'],
    arg=>['str*'=>{default=>'en_US'}];

has_clause 'name',
    prio=>2, tags=>['meta', 'defhash'],
    arg=>'str*';

has_clause 'summary',
    prio=>2, tags=>['meta', 'defhash'],
    arg=>'str*';

has_clause 'description',
    prio=>2, tags=>['meta', 'defhash'],
    arg=>'str*';

has_clause 'tags',
    prio=>2, tags=>['meta', 'defhash'],
    arg=>['array*', of=>'str*'];

has_clause 'req',
    prio       => 3,
    tags       => ['constraint'],
    arg        => 'bool',
    allow_expr => 1,
    ;
has_clause 'forbidden',
    prio       => 3,
    tags       => ['constraint'],
    arg        => 'bool',
    allow_expr => 1,
    ;
has_clause 'ok',
    prio=>50, tags=>['constraint'],
    arg=>'any',;

#has_clause 'if', tags=>['constraint'];

#has_clause 'each', tags=>['constraint'];

#has_clause 'check_each', tags=>['constraint'];

#has_clause 'exists', tags=>['constraint'];

#has_clause 'check_exists', tags=>['constraint'];

#has_clause 'check', arg=>'expr*', tags=>['constraint'];

#has_clause 'clset',
#    prio=>50, tags=>['constraint'],
#    arg=>['clset*'];

#has_clause 'clause',
#    tags    => ['constraint'],
#    prio    => 50,
#    arg     => ['array*' => elems => ['clname*', 'any']],
#    ;
# has_clause 'postfilters',
#     tags       => ['filter'],
#     prio       => 90,
#     arg        => ['array*' => of=>'expr*'],
#     attrs      => {
#         temp => {
#         },
#     }
#     ;

1;
# ABSTRACT: Base type

=for Pod::Coverage ^(clause_.+|clausemeta_.+)$
