package Data::Sah::Type::HasElems;

# DATE
# VERSION

use Data::Sah::Util::Role 'has_clause';
use Role::Tiny;

requires 'superclause_has_elems';

has_clause 'max_len',
    prio       => 51,
    arg        => ['int*' => {min=>0}],
    allow_expr => 1,
    code       => sub {
        my ($self, $cd) = @_;
        $self->superclause_has_elems('max_len', $cd);
    };

has_clause 'min_len',
    arg        => ['int*' => {min=>0}],
    allow_expr => 1,
    code       => sub {
        my ($self, $cd) = @_;
        $self->superclause_has_elems('min_len', $cd);
    };

has_clause 'len_between',
    arg        => ['array*' => {elems => ['int*', 'int*']}],
    allow_expr => 1,
    code       => sub {
        my ($self, $cd) = @_;
        $self->superclause_has_elems('len_between', $cd);
    };

has_clause 'len',
    arg        => ['int*' => {min=>0}],
    allow_expr => 1,
    code       => sub {
        my ($self, $cd) = @_;
        $self->superclause_has_elems('len', $cd);
    };

has_clause 'has',
    arg        => 'any',
    allow_expr => 1,
    code       => sub {
        my ($self, $cd) = @_;
        $self->superclause_has_elems('has', $cd);
    };

has_clause 'each_index',
    arg        => 'schema*',
    allow_expr => 0,
    code       => sub {
        my ($self, $cd) = @_;
        $self->superclause_has_elems('each_index', $cd);
    };

has_clause 'each_elem',
    arg        => 'schema*',
    allow_expr => 0,
    code       => sub {
        my ($self, $cd) = @_;
        $self->superclause_has_elems('each_elem', $cd);
    };

has_clause 'check_each_index',
    arg        => 'schema*',
    allow_expr => 0,
    code       => sub {
        my ($self, $cd) = @_;
        $self->superclause_has_elems('check_each_index', $cd);
    };

has_clause 'check_each_elem',
    arg        => 'schema*',
    allow_expr => 0,
    code       => sub {
        my ($self, $cd) = @_;
        $self->superclause_has_elems('check_each_elem', $cd);
    };

has_clause 'uniq',
    arg        => 'schema*',
    allow_expr => 1,
    code       => sub {
        my ($self, $cd) = @_;
        $self->superclause_has_elems('uniq', $cd);
    };

has_clause 'exists',
    arg        => 'schema*',
    allow_expr => 0,
    code       => sub {
        my ($self, $cd) = @_;
        $self->superclause_has_elems('exists', $cd);
    };

# has_prop 'len';

# has_prop 'elems';

# has_prop 'indices';

1;
# ABSTRACT: HasElems role

=for Pod::Coverage ^(clause_.+|clausemeta_.+)$
