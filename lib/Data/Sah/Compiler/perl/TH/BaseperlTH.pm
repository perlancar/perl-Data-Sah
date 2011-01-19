package Data::Sah::Compiler::perl::TH::Base;
# ABSTRACT: Base class for Perl type-emitters

use Any::Moose;
extends 'Data::Sah::Compiler::ProgBase::TH::BaseProgTH';

sub before_clause {
}

sub clause_PREPROCESS {
}

sub clause_SANITY {
    my ($self, %args) = @_;
    my $clause = $args{clause};
    my $e = $self->compiler;

    # no need to allow undef is required/set is true
    my $cs = $clause->{cs};
    return if
        ($cs->{required} && $cs->{required}{value} &&
            !$cs->{required}{attrs}{expr});

    $e->line('unless (defined($data)) { $res->{success} = 1; last ATTRS }');
    {};
}

sub clause_default {
    my ($self, %args) = @_;
    my $clause = $args{clause};
    my $e = $self->compiler;
    my $t = $e->data_term;
    my $v = $clause->{value_term};

    {
        stmt => "$t //= $v",
    };
}

sub clause_required {
    my ($self, %args) = @_;
    my $clause = $args{clause};
    my $e = $self->compiler;

    $e->errif($clause, "($clause->{value}) && !defined(\$data)", 'last ATTRS');
}

sub clause_forbidden {
    my ($self, %args) = @_;
    my $clause = $args{clause};
    my $e = $self->compiler;

    $e->errif($clause, "($clause->{value}) && defined(\$data)", 'last ATTRS');
}

sub clause_prefilters {
}

sub clause_postfilters {
}

sub clause_lang {
}

sub clause_deps {
}

sub clause_check {
    my ($self, %args) = @_;
    my $clause = $args{clause};
    my $e = $self->compiler;

    $e->errif($clause, '!$arg', 'last ATTRS');
}

sub superclause_comparable {
    my ($self, %args) = @_;
    my $clause = $args{clause};
    my $which = $args{which};
    my $e = $self->compiler;

    if ($which =~ /^(one_of|is)$/) {
        $e->var('choices');
        $e->line('$choices = ', ($which eq 'is' ? "[$clause->{value}]" : $clause->{value}), ';');
        $e->var(err => 1);
        $e->line('for (@$choices) {')->inc_indent;
        $e->line(    'if (', $self->eq(va=>'$data', vb=>'$_'), ') { $err = 0; last }');
        $e->dec_indent->line('}');
    } elsif ($which =~ /^(not_one_of|isnt)$/) {
        $e->var('choices');
        $e->line('$choices = ', ($which eq 'isnt' ? "[$clause->{value}]" : $clause->{value}), ';');
        $e->var(err => 0);
        $e->line('for (@$choices) {')->inc_indent;
        $e->line(    'if (', $self->eq(va=>'$data', vb=>'$_'), ') { $err = 1; last }');
        $e->dec_indent->line('}');
    } else {
        die "Bug: mattr_comparable($which) is not defined";
    }
    $e->errif($clause, '$err');
}

sub superclause_sortable {
    my ($self, %args) = @_;
    my $clause = $args{clause};
    my $which = $args{which};
    my $e = $self->compiler;

    my $x;
    if ($which =~ /^(ge|gt|le|lt)$/) {
        my $x =
            $which eq 'ge' ? '<  0' :
            $which eq 'gt' ? '<= 0' :
            $which eq 'le' ? '>  0' :
                             '>= 0';
        $e->errif($clause, $self->cmp(va=>'$data', vb=>$clause->{value}) . ' ' . $x);
    } elsif ($which eq 'between') {
        $e->errif($clause,
                  $self->cmp(va=>'$data', vb=>$clause->{value}."->[0]") . ' < 0 && ' .
                  $self->cmp(va=>'$data', vb=>$clause->{value}."->[1]") . ' > 0'
              );
    } else {
        die "Bug: mattr_sortable($which) is not defined";
    }
}

# XXX superclause_has_elems

no Any::Moose;
1;
