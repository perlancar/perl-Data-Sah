package Data::Sah::Type::HasElems;

use Moo::Role;
use Data::Sah::Util 'has_clause';

# VERSION

requires 'superclause_has_elems';

has_clause 'max_len',
    arg        => ['int*' => {min=>0}],
    allow_expr => 1,
    code    => sub {
        my ($self, $cd) = @_;
        $self->superclause_has_elems('max_len', $cd);
    };

has_clause 'min_len',
    arg     => ['int*' => {min=>0}],
    allow_expr => 1,
    code    => sub {
        my ($self, $cd) = @_;
        $self->superclause_has_elems('min_len', $cd);
    };

has_clause 'len_between',
    arg   => ['array*' => {elems => ['int*', 'int*']}],
    allow_expr => 1,
    code  => sub {
        my ($self, $cd) = @_;
        $self->superclause_has_elems('len_between', $cd);
    };

has_clause 'len',
    arg   => ['int*' => {min=>0}],
    allow_expr => 1,
    code  => sub {
        my ($self, $cd) = @_;
        $self->superclause_has_elems('len', $cd);
    };

has_clause 'has',
    arg => 'any',
    allow_expr => 1,
    code => sub {
        my ($self, $cd) = @_;
        $self->superclause_has_elems('has', $cd);
    };

# has_clause 'each_index';

has_clause 'each_elem',
    arg => 'schema*',
    allow_expr => 0,
    code => sub {
        my ($self, $cd) = @_;
        $self->superclause_has_elems('each_elem', $cd);
    };

# has_clause 'check_each_index';

# has_clause 'check_each_elem';

# has_clause 'uniq';

# has_clause 'exists';

# has_prop 'len';

# has_prop 'elems';

# has_prop 'indices';

1;
# ABSTRACT: HasElems role

=cut
