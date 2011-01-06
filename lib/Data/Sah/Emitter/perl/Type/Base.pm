package Data::Sah::Emitter::perl::Type::Base;
# ABSTRACT: Base class for Perl type-emitters

use Any::Moose;
extends 'Data::Sah::Emitter::ProgBase::Type::Base';

sub before_clause {
}

sub clause_PREPROCESS {
}

sub clause_SANITY {
    my ($self, %args) = @_;
    my $attr = $args{attr};
    my $e = $self->emitter;

    # no need to allow undef is required/set is true
    my $ah = $attr->{ah};
    return if
        ($ah->{required} && $ah->{required}{value} &&
            !$ah->{required}{attrs}{expr}) ||
                 ($ah->{set} && $ah->{set}{value} &&
                      !$ah->{set}{attrs}{expr});

    $e->line('unless (defined($data)) { $res->{success} = 1; last ATTRS }');
}

sub clause_default {
    my ($self, %args) = @_;
    my $attr = $args{attr};
    my $e = $self->emitter;

    $e->line('unless (defined($data)) { $data = ', $attr->{value}, ' }');
}

sub clause_required {
    my ($self, %args) = @_;
    my $attr = $args{attr};
    my $e = $self->emitter;

    $e->errif($attr, "($attr->{value}) && !defined(\$data)", 'last ATTRS');
}

sub clause_forbidden {
    my ($self, %args) = @_;
    my $attr = $args{attr};
    my $e = $self->emitter;

    $e->errif($attr, "($attr->{value}) && defined(\$data)", 'last ATTRS');
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
    my $attr = $args{attr};
    my $e = $self->emitter;

    $e->errif($attr, '!$arg', 'last ATTRS');
}

sub superclause_comparable {
    my ($self, %args) = @_;
    my $attr = $args{attr};
    my $which = $args{which};
    my $e = $self->emitter;

    if ($which =~ /^(one_of|is)$/) {
        $e->var('choices');
        $e->line('$choices = ', ($which eq 'is' ? "[$attr->{value}]" : $attr->{value}), ';');
        $e->var(err => 1);
        $e->line('for (@$choices) {')->inc_indent;
        $e->line(    'if (', $self->eq(va=>'$data', vb=>'$_'), ') { $err = 0; last }');
        $e->dec_indent->line('}');
    } elsif ($which =~ /^(not_one_of|isnt)$/) {
        $e->var('choices');
        $e->line('$choices = ', ($which eq 'isnt' ? "[$attr->{value}]" : $attr->{value}), ';');
        $e->var(err => 0);
        $e->line('for (@$choices) {')->inc_indent;
        $e->line(    'if (', $self->eq(va=>'$data', vb=>'$_'), ') { $err = 1; last }');
        $e->dec_indent->line('}');
    } else {
        die "Bug: mattr_comparable($which) is not defined";
    }
    $e->errif($attr, '$err');
}

sub superclause_sortable {
    my ($self, %args) = @_;
    my $attr = $args{attr};
    my $which = $args{which};
    my $e = $self->emitter;

    my $x;
    if ($which =~ /^(ge|gt|le|lt)$/) {
        my $x =
            $which eq 'ge' ? '<  0' :
            $which eq 'gt' ? '<= 0' :
            $which eq 'le' ? '>  0' :
                             '>= 0';
        $e->errif($attr, $self->cmp(va=>'$data', vb=>$attr->{value}) . ' ' . $x);
    } elsif ($which eq 'between') {
        $e->errif($attr,
                  $self->cmp(va=>'$data', vb=>$attr->{value}."->[0]") . ' < 0 && ' .
                  $self->cmp(va=>'$data', vb=>$attr->{value}."->[1]") . ' > 0'
              );
    } else {
        die "Bug: mattr_sortable($which) is not defined";
    }
}

# XXX superclause_has_elems

no Any::Moose;
1;
