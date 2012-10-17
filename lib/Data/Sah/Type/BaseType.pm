package Data::Sah::Type::BaseType;
# why name it BaseType instead of Base? because I'm sick of having 5 files named
# Base.pm in my editor (there would be Type::Base and the various
# Compiler::*::Type::Base).

use Moo::Role;
#use Data::Sah::Schemas::Common;
#use Data::Sah::Schemas::Schema;
use Data::Sah::Util 'has_clause';

# VERSION

requires 'handle_type_check';

# XXX define 'cset' schema

has_clause 'v',
    prio=>0, tags=>['meta', 'defhash'],
    arg=>['int*'=>{is=>1}];

#has_clause 'defhash_v';

#has_clause 'schema_v';

#has_clause 'base_v';

has_clause 'default',
    prio=>1, tags=>[],
    arg=>'any';

#has_clause 'prefilters', prio=>10, arg=>'((expr*)[])*', tags=>[''], attrs=>{perm=>{}};

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
    prio=>3, tags=>['constraint'],
    arg=>'bool';

has_clause 'forbidden',
    prio=>3, tags=>['constraint'],
    arg=>'bool';

has_clause 'ok',
    prio=>50, tags=>['constraint'],
    arg=>'any',;

#has_clause 'if';

#has_clause 'each';

#has_clause 'check_each';

#has_clause 'exists';

#has_clause 'check_exists';

#has_clause 'check', arg=>'expr*', tags=>['constraint'];

#has_clause 'cset',
#    prio=>50, tags=>['constraint'],
#    arg=>['cset*'];

#has_clause 'postfilters', prio=>90, arg=>'((expr*)[])*', tags=>[''];

1;
# ABSTRACT: Base type

=cut
