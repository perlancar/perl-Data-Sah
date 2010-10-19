package Data::Schema::Emitter::Perl::Type::Base;
# ABSTRACT: Base class for Perl type-emitters

use Any::Moose;
extends 'Data::Schema::Emitter::Base::Type::Base';

has 'emitter' => (is => 'rw');

sub before_attr {
    my ($self, %args) = @_;
    my $attr = $args{attr};
    my $e = $self->emitter;
    if ($attr->{name} eq 'SANITY') {
        $e->line('unless (defined($data)) { $res->{success} = 1; last ATTRS }');
    }
}

sub attr_SANITY {
}

sub attr_default {
    my ($self, %args) = @_;
    my $attr = $args{attr};
    my $e = $self->emitter;

    $e->line('unless (defined($data)) { $data = ', $attr->{value}, ' }');
}

sub attr_required {
    my ($self, %args) = @_;
    my $attr = $args{attr};
    my $e = $self->emitter;

    $e->errif($attr, "($attr->{value}) && !defined(\$data)", 'last ATTRS');
}

sub attr_forbidden {
    my ($self, %args) = @_;
    my $attr = $args{attr};
    my $e = $self->emitter;

    $e->errif($attr, "($attr->{value}) && defined(\$data)", 'last ATTRS');
}

sub attr_set {
    my ($self, %args) = @_;
    my $attr = $args{attr};
    my $e = $self->emitter;

    $e->line("if (defined $attr->{value}) {")->inc_indent;
    $e->errif($attr, "$attr->{value} && !defined(\$data)", 'last ATTRS');
    $e->errif($attr, "!$attr->{value} && defined(\$data)", 'last ATTRS');
    $e->dec_indent->line('}');
}

sub attr_prefilters {
}

sub attr_postfilters {
}

sub attr_lang {
}

sub attr_deps {
}

sub attr_check {
    my ($self, %args) = @_;
    my $attr = $args{attr};
    my $e = $self->emitter;

    $e->errif($attr, '!$arg', 'last ATTRS');
}

sub mattr_comparable {
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

# XXX mattr_haselement

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
