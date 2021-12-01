package Data::Sah::Type::HasElems;

use strict;

use Data::Sah::Util::Role 'has_clause';
use Role::Tiny;

requires 'superclause_has_elems';

has_clause 'max_len',
    v => 2,
    prio       => 51,
    tags       => ['constraint'],
    schema     => ['int', {min=>0}],
    allow_expr => 1,
    code       => sub {
        my ($self, $cd) = @_;
        $self->superclause_has_elems('max_len', $cd);
    };

has_clause 'min_len',
    v => 2,
    tags       => ['constraint'],
    schema     => ['int', {min=>0}],
    allow_expr => 1,
    code       => sub {
        my ($self, $cd) = @_;
        $self->superclause_has_elems('min_len', $cd);
    };

has_clause 'len_between',
    v => 2,
    tags       => ['constraint'],
    schema     => ['array' => {req=>1, len=>2, elems => [
        [int => {req=>1}],
        [int => {req=>1}],
    ]}],
    allow_expr => 1,
    code       => sub {
        my ($self, $cd) = @_;
        $self->superclause_has_elems('len_between', $cd);
    };

has_clause 'len',
    v => 2,
    tags       => ['constraint'],
    schema     => ['int', {min=>0}],
    allow_expr => 1,
    code       => sub {
        my ($self, $cd) = @_;
        $self->superclause_has_elems('len', $cd);
    };

has_clause 'has',
    v => 2,
    tags       => ['constraint'],
    schema       => ['_same_elem', {req=>1}],
    inspect_elem => 1,
    prio         => 55, # we should wait for clauses like e.g. 'each_elem' to coerce elements
    allow_expr   => 1,
    code         => sub {
        my ($self, $cd) = @_;
        $self->superclause_has_elems('has', $cd);
    };

has_clause 'each_index',
    v => 2,
    tags       => ['constraint'],
    schema     => ['sah::schema', {req=>1}],
    subschema  => sub { $_[0] },
    allow_expr => 0,
    code       => sub {
        my ($self, $cd) = @_;
        $self->superclause_has_elems('each_index', $cd);
    };

has_clause 'each_elem',
    v => 2,
    tags       => ['constraint'],
    schema     => ['sah::schema', {req=>1}],
    inspect_elem => 1,
    subschema  => sub { $_[0] },
    allow_expr => 0,
    code       => sub {
        my ($self, $cd) = @_;
        $self->superclause_has_elems('each_elem', $cd);
    };

has_clause 'check_each_index',
    v => 2,
    tags       => ['constraint'],
    schema     => ['sah::schema', {req=>1}],
    subschema  => sub { $_[0] },
    allow_expr => 0,
    code       => sub {
        my ($self, $cd) = @_;
        $self->superclause_has_elems('check_each_index', $cd);
    };

has_clause 'check_each_elem',
    v => 2,
    tags       => ['constraint'],
    schema     => ['sah::schema', {req=>1}],
    inspect_elem => 1,
    subschema  => sub { $_[0] },
    allow_expr => 0,
    code       => sub {
        my ($self, $cd) = @_;
        $self->superclause_has_elems('check_each_elem', $cd);
    };

has_clause 'uniq',
    v => 2,
    tags       => ['constraint'],
    schema     => ['bool', {}],
    inspect_elem => 1,
    prio         => 55, # we should wait for clauses like e.g. 'each_elem' to coerce elements
    subschema  => sub { $_[0] },
    allow_expr => 1,
    code       => sub {
        my ($self, $cd) = @_;
        $self->superclause_has_elems('uniq', $cd);
    };

has_clause 'exists',
    v => 2,
    tags       => ['constraint'],
    schema     => ['sah::schema', {req=>1}],
    inspect_elem => 1,
    subschema  => sub { $_[0] },
    allow_expr => 0,
    code       => sub {
        my ($self, $cd) = @_;
        $self->superclause_has_elems('exists', $cd);
    };

# has_prop 'len';

# has_prop 'elems';

# has_prop 'indices';

# AUTHORITY
# DATE
# DIST
# VERSION

1;
# ABSTRACT: HasElems role

=for Pod::Coverage ^(clause_.+|clausemeta_.+)$
