package Data::Sah::Type::BaseType;
# why name it BaseType instead of Base? because I'm sick of having 5 files named
# Base.pm in my editor (there would be Type::Base and the various
# Compiler::*::Type::Base).

use Moo::Role;
#use Data::Sah::Schemas::Common;
#use Data::Sah::Schemas::Schema;
use Data::Sah::Util 'has_clause';

# VERSION

# XXX define 'cset' schema

has_clause 'v',
    prio=>0, tags=>['meta', 'defhash'],
    arg=>['int*'=>{is=>1}];

has_clause 'default',
    prio=>1, tags=>[],
    arg=>'any';

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

has_clause 'noop',
    prio=>50, tags=>['constraint'],
    arg=>'any',;

has_clause 'fail',
    prio=>50, tags=>['constraint'],
    arg=>'bool';

#has_clause 'cset',
#    prio=>50, tags=>['constraint'],
#    arg=>['cset*'];

#has_clause 'if',
#    prio=>50, tags=>['constraint'],
#    arg=>['any*'=>{of=>[
#        ['array*'=>{elems=>['cname*', 'any', 'cname*', 'any']}], # 4-arg form
#        ['array*'=>{elems=>['cset*' , 'cset*' ]}], # 2-arg form (cset)
#        ['array*'=>{elems=>['csets*', 'csets*']}], # 2-arg form (csets)
#    ]}];

#has_clause 'prefilters', prio=>10, arg=>'((expr*)[])*', tags=>[''];

#has_clause 'postfilters', prio=>90, arg=>'((expr*)[])*', tags=>[''];

#has_clause 'check', arg=>'expr*', tags=>['constraint'];

1;
# ABSTRACT: Specification for base type

=cut
