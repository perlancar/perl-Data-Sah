package Data::Schema::Emitter::Perl::Type::Base;
# ABSTRACT: Base class for Perl type emitters

use Any::Moose;

has 'emitter' => (is => 'rw');

sub before_attr {
    my ($self, %args) = @_;
    my $attr = $args{attr};
    my $e = $self->emitter;
    if ($attr->{name} eq 'SANITY') {
        $e->line('unless (defined($data)) { $res->{success} = 1; return $res }');
    }
}

sub attr_SANITY {
}

sub attr_default {
    my ($self, %args) = @_;
    my $attr = $args{attr};
    my $e = $self->emitter;
    $e->line('unless (defined($data)) { $data = ', $e->dump($attr->{value}), ' }');
}

sub attr_required {
    my ($self, %args) = @_;
    my $attr = $args{attr};
    my $e = $self->emitter;
    return unless $attr->{value};
    {err_cond => '!defined($data)', skip_remaining_on_err => 1};
}

sub attr_forbidden {
    my ($self, %args) = @_;
    my $attr = $args{attr};
    my $e = $self->emitter;
    return unless $attr->{value};
    {err_cond => 'defined($data)', skip_remaining_on_err => 1};
}

sub attr_set {
    my ($self, %args) = @_;
    my $attr = $args{attr};
    my $e = $self->emitter;
    return unless defined($attr->{value});
    if ($attr->{value}) {
        $self->attr_required(attr=>$attr);
    } else {
        $self->attr_forbidden(attr=>$attr);
    }
}

sub attr_prefilters {
}

sub attr_postfilters {
}

sub attr_lang {
}

sub attr_deps {
}

sub attr_all {
}

sub attr_either {
}

sub attr_check {
}

sub mattr_comparable {
    my ($self, %args) = @_;
    my $attr = $args{attr};
    my $which = $args{which};
    my $e = $self->emitter;

    if ($which =~ /^(one_of|is)$/) {
        $e->var(choices => ($which eq 'is' ? [$attr->{value}] : $attr->{value}));
        $e->var(err => 1);
        $e->line('for (@$choices) {')->inc_indent;
        $e->line(    'if (', $self->eq(va=>'$data', vb=>'$_'), ') { $err = 0; last }');
        $e->dec_indent->line('}');
    } elsif ($which =~ /^(not_one_of|isnt)$/) {
        $e->var(choices => $which eq 'isnt' ? [$attr->{value}] : $attr->{value});
        $e->var(err => 0);
        $e->line('for (@$choices) {')->inc_indent;
        $e->line(    'if (', $self->eq(va=>'$data', vb=>'$_'), ') { $err = 1; last }');
        $e->dec_indent->line('}');
    } else {
        die "Bug: mattr_comparable($which) is not defined";
    }
    {err_cond => '$err'};
}

sub mattr_sortable {
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
        return { err_cond => $self->cmp(va=>'$data', b=>$attr->{value}) . ' ' . $x };
    } elsif ($which eq 'between') {
        return { err_cond =>
                     $self->cmp(va=>'$data', b=>$attr->{value}[0]) . ' < 0 && ' .
                     $self->cmp(va=>'$data', b=>$attr->{value}[1]) . ' > 0'
                 };
    } else {
        die "Bug: mattr_sortable($which) is not defined";
    }
}

# XXX mattr_haselement

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
