package Data::Schema::Emitter::Base;
# ABSTRACT: Base class for Data::Schema::Emitter::*

use Any::Moose;
use Data::Dumper;
use Log::Any qw($log);

=head1 ATTRIBUTES

=head2 main

Reference to the main Data::Schema module.

=cut

has 'main' => (is => 'rw');

=head2 config

Config object. See Data::Schema::Emitter::$EMITTER::Config.

=cut

has 'config' => (is => 'rw');

=head2 result

Result of emit() should be stored here.

=cut

has 'result' => (is => 'rw');

=head2 states

Various states like current 'lang', 'prefilters', 'postfilters'.

=cut

has 'states' => (is => 'rw', default => sub { {} });

=head2 type_handlers

A hashref of type names and type handlers.

=cut

has 'type_handlers' => (is => 'rw', default => sub { {} });

=head1 METHODS

=cut

sub BUILD {
    my ($self) = @_;
    my $name = ref($self) . "::Type::";
    for (@{ $self->main->type_roles }) {
        $log->trace("Trying to require $name$_");
        eval "require $name$_";
        die "Can't load $name$_: $@" if $@;
        $self->install_type_handler("$name$_");
    }
}

=head2 valid_attr($type, $name)

Check whether attribute named $name is valid for type $type.

=cut

sub valid_attr {
    my ($self, $type, $name) = @_;
    my $th = $self->type_handlers->{$type};
    return unless $th;
    no strict 'refs';
    for my $r (@{ $th->meta->roles }) {
        my $n = $r->name;
        $n .= "::typenames";
        next unless $$n; # not a ds type role
        return 1 if $r->requires_method("attr_$name") ||
            $r->has_method("attr_$name");
    }
    0;
}

=head2 emit($schema)

Emit schema into final format. This will call various other methods
like before_emit(), before_attr(), def(), after_attr(), after_emit()
which must be supplied by subclasses. It also calls attr_*() which
should be supplied by emitter's type handlers. These called methods
should modify the 'result' attribute. Finally the 'result' will be
returned.

=cut

sub emit {
    my ($self, $schema) = @_;
    $self->_emit($schema);
}

sub _emit {
    my ($self, $schema, $inner, $met_types) = @_;
    $met_types //= [];
    $log->tracef("Entering _emit(schema = %s, inner = %s, met_types = %s)", $schema, $inner, $met_types);

    my $main = $self->main;
    $schema = $main->normalize_schema($schema);
    $log->tracef("Normalized schema, result=%s", $schema);
    die "Can't normalize schema: $schema" unless ref($schema);

    my $before_emit_result;
    unless ($inner) {
        $self->result(undef);
        $log->tracef("Calling before_emit()");
        $before_emit_result = $self->before_emit(schema => $schema);
    }

    if (ref($before_emit_result) eq 'HASH') {
        goto FINISH2 if $before_emit_result->{skip_emit};
    }

    my $saved_types;
    if (keys %{ $schema->{def} }) {
        # since def introduce new schemas into the system, we need to
        # save the original type list first and restore when this
        # schema is out of scope.
        $saved_types = { %{$main->type_names} };

        for (keys %{ $schema->{def} }) {
            die "Invalid name in def: $_" unless /^[?]?\w+$/;
            my $def = $schema->{def}{$_};
            $log->tracef("Calling def(name => %s, def => %s)", $_, $def);
            $self->def(name => $_, def => $def);
            $log->tracef("Return from def()");
        }
    }

    my $type = $schema->{type};
    unless ($main->type_names->{$type}) {
        # give a chance for plugins to automatically load types
        $main->_call_plugin_hook("unknown_type", $type);
    }
    my $th0 = $main->type_names->{$type};
    die "Unknown type `$type`" unless $th0;

    if (ref($th0) eq 'HASH') {
        $log->tracef("Schema is defined in terms of another schema: $type");
        die "Recursive definition: " . join(" -> ", @$met_types) . " -> $type"
            if grep { $_ eq $type } @$met_types;
        push @{ $met_types }, $type;
        $self->_emit({ type => $th0->{type},
                       attr_hashes => [@{ $th0->{attr_hashes} }, @{ $schema->{attr_hashes} }],
                       def => $th0->{def} }, "inner", $met_types);
        goto FINISH;
    }

    local $self->states->{lang} = ($self->states->{lang} // ($ENV{LANG} && $ENV{LANG} =~ /^(\w{2})/ ? $1 : undef) // "en");
    local $self->states->{prefilters}  = ($self->states->{prefilters}  ? [@{$self->states->{prefilters}}]  : []);
    local $self->states->{postfilters} = ($self->states->{postfilters} ? [@{$self->states->{postfilters}}] : []);
    local $self->states->{level} = ($self->states->{level} // "error");

    $log->tracef("Getting type handler for type %s", $type);
    my $th = $self->get_type_handler($type);
    die "Emitter ".ref($self)." can't handle type `$type` yet" unless $th;

    my $attr_hashes = $schema->{attr_hashes};
    if (@$attr_hashes > 1) {
        $log->tracef("Merging attribute hashes: %s", $attr_hashes);
        my $res = $main->_merge_attr_hashes($attr_hashes);
        $log->tracef("Merge result: %s", $res);
        die "Can't merge attribute hashes: $res->{error}" unless $res->{success};
        $attr_hashes = $res->{result};
    }

    my @attrs;
    for my $i (0..@$attr_hashes-1) {
        for (keys %{ $attr_hashes->[$i] }) {
            my ($name, $params);
            if (/^([_a-z]\w*)\??(.*)$/) {
                ($name, $params) = ($1, $2);
            } elsif (/^([_a-z]\w*):(\w+)$/) {
                # compatibility with old suffix syntax (DS 0.13 and earlier)
                ($name, $params) = ($1, $2);
            } else {
                die "Invalid attribute syntax: $_";
            }
            next if $name =~ /^_/;
            die "Invalid attribute for $type: $name"
                unless $self->valid_attr($type, $name);
            push @attrs, {i=>$i, name=>$name,
                          params => $main->_parse_attr_params($params),
                          value => $attr_hashes->[$i]{$_},
                          ref_to_attr_hash => $attr_hashes->[$i]};
        }
    }

    for (qw/SANITY/) {
        push @attrs, {i=>0, req=>0, name=>$_, value=>undef, ref_to_attr_hash=>$attr_hashes->[0]};
    }

    my $sort_attr_sub = sub {
        my $pa = "attrprio_" . $a->{name}; $pa = $th->$pa;
        my $pb = "attrprio_" . $b->{name}; $pb = $th->$pb;
        # XXX sort by expression dependency in attrhash[i] ||
        $pa <=> $pb ||
        $a->{i} <=> $b->{i} ||
        $a->{name} cmp $b->{name}
    };

    @attrs = sort $sort_attr_sub @attrs;

    $th->before_all_attrs(attrs => \@attrs) if $th->can("before_all_attrs");

    for my $attr (@attrs) {
        $self->before_attr(attr => $attr);
        $th->before_attr(attr => $attr) if $th->can("before_attr");
        my $meth = "attr_$attr->{name}";
        my $attr_method_result;
        if ($th->can($meth)) {
            $log->tracef("Calling %s(attr=%s)", $meth,
                         $attr);
            $attr_method_result = $th->$meth(attr => $attr);
            $log->tracef("Return from %s()", $meth);
        } else {
            die sprintf("Type handler (%s) doesn't have method %s()", ref($th), $meth)
                if $attr->{req};
        }
        $th->after_attr(attr => $attr, attr_method_result => $attr_method_result, th => $th)
            if $th->can("after_attr");
        $self->after_attr(attr => $attr, attr_method_result => $attr_method_result, th => $th);
    }

    $th->after_all_attrs(attrs => \@attrs) if $th->can("after_all_attrs");

  FINISH:

    $main->type_names($saved_types) if $saved_types;

    unless ($inner) {
        $log->tracef("Calling after_emit()");
        $self->after_emit(schema => $schema);
    }

  FINISH2:

    $log->trace("Leaving emit()");
    $self->result;
}

sub install_type_handler {
    my ($self, $module) = @_;
    eval "require $module;";
    die "Can't load type handler `$module`: $@" if $@;
    my $th = $module->new(emitter => $self);
    # find out the type names
    my $tn = [];
    for my $r (@{ $th->meta->roles }) {
        my $n = $r->name;
        $n .= "::typenames";
        no strict 'refs';
        if ($$n) {
            push @$tn, ref($$n) eq 'ARRAY' ? @{$$n} : $$n;
        }
    }
    die "Class $module does not consume any DS type role ".
        "(Data::Schema::Type::*)" unless @$tn;
    for (@$tn) {
        die "Class $module tried to define already-defined type `$_`"
            if $self->type_handlers->{$_};
        $self->type_handlers->{$_} = $th;
    }
}

sub get_type_handler {
    my ($self, $name) = @_;
    $self->type_handlers->{$name};
}

sub def {
    my ($self, %args) = @_;
    my $main = $self->main;
    my $tn = $main->type_names;

    my $name = $args{name};
    my $def = $args{def};
    my $optional = $name =~ s/^\?//;
    if ($tn->{$name}) {
        return if $optional;
        die "Replacing builtin type currently not allowed ($name)" if !ref($tn->{$name});
        delete $tn->{$name};
    }
    $main->register_schema($def, $name);
}

sub before_emit {
    # child should override this
}

sub after_emit {
    # child should override this
}

sub before_attr {
    # child can override this
}

sub after_attr {
    # child can override this
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
