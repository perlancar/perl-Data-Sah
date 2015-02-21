package Data::Sah::Compiler::human::TH::hash;

# DATE
# VERSION

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Mo qw(build default);
use Role::Tiny::With;

extends 'Data::Sah::Compiler::human::TH';
with 'Data::Sah::Compiler::human::TH::Comparable';
with 'Data::Sah::Compiler::human::TH::HasElems';
with 'Data::Sah::Type::hash';

sub handle_type {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    $c->add_ccl($cd, {
        fmt   => ["hash", "hashes"],
        type  => 'noun',
    });
}

sub clause_has {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;

    $c->add_ccl($cd, {
        expr=>1, multi=>1,
        fmt => "%(modal_verb)s have %s in its field values"});
}

sub clause_each_index {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $cv = $cd->{cl_value};

    my %iargs = %{$cd->{args}};
    $iargs{outer_cd}             = $cd;
    $iargs{schema}               = $cv;
    $iargs{schema_is_normalized} = 0;
    my $icd = $c->compile(%iargs);

    $c->add_ccl($cd, {
        type  => 'list',
        fmt   => 'field name %(modal_verb)s be',
        items => [
            $icd->{ccls},
        ],
        vals  => [],
    });
}

sub clause_each_elem {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $cv = $cd->{cl_value};

    my %iargs = %{$cd->{args}};
    $iargs{outer_cd}             = $cd;
    $iargs{schema}               = $cv;
    $iargs{schema_is_normalized} = 0;
    my $icd = $c->compile(%iargs);

    $c->add_ccl($cd, {
        type  => 'list',
        fmt   => 'each field %(modal_verb)s be',
        items => [
            $icd->{ccls},
        ],
        vals  => [],
    });
}

sub clause_keys {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $cv = $cd->{cl_value};

    for my $k (sort keys %$cv) {
        local $cd->{spath} = [@{$cd->{spath}}, $k];
        my $v = $cv->{$k};
        my %iargs = %{$cd->{args}};
        $iargs{outer_cd}             = $cd;
        $iargs{schema}               = $v;
        $iargs{schema_is_normalized} = 0;
        my $icd = $c->compile(%iargs);
        $c->add_ccl($cd, {
            type  => 'list',
            fmt   => 'field %s %(modal_verb)s be',
            vals  => [$k],
            items => [ $icd->{ccls} ],
        });
    }
}

sub clause_re_keys {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $cv = $cd->{cl_value};

    for my $k (sort keys %$cv) {
        local $cd->{spath} = [@{$cd->{spath}}, $k];
        my $v = $cv->{$k};
        my %iargs = %{$cd->{args}};
        $iargs{outer_cd}             = $cd;
        $iargs{schema}               = $v;
        $iargs{schema_is_normalized} = 0;
        my $icd = $c->compile(%iargs);
        $c->add_ccl($cd, {
            type  => 'list',
            fmt   => 'fields whose names match regex pattern %s %(modal_verb)s be',
            vals  => [$k],
            items => [ $icd->{ccls} ],
        });
    }
}

sub clause_req_keys {
  my ($self, $cd) = @_;
  my $c  = $self->compiler;

  $c->add_ccl($cd, {
    fmt   => q[%(modal_verb)s have required fields %s],
    expr  => 1,
  });
}

sub clause_allowed_keys {
  my ($self, $cd) = @_;
  my $c  = $self->compiler;

  $c->add_ccl($cd, {
    fmt   => q[%(modal_verb)s only have these allowed fields %s],
    expr  => 1,
  });
}

sub clause_allowed_keys_re {
  my ($self, $cd) = @_;
  my $c  = $self->compiler;

  $c->add_ccl($cd, {
    fmt   => q[%(modal_verb)s only have fields matching regex pattern %s],
    expr  => 1,
  });
}

sub clause_forbidden_keys {
  my ($self, $cd) = @_;
  my $c  = $self->compiler;

  $c->add_ccl($cd, {
    fmt   => q[%(modal_verb_neg)s have these forbidden fields %s],
    expr  => 1,
  });
}

sub clause_forbidden_keys_re {
  my ($self, $cd) = @_;
  my $c  = $self->compiler;

  $c->add_ccl($cd, {
    fmt   => q[%(modal_verb_neg)s have fields matching regex pattern %s],
    expr  => 1,
  });
}

1;
# ABSTRACT: human's type handler for type "hash"

=for Pod::Coverage ^(clause_.+|superclause_.+)$
