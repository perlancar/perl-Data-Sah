package Data::Schema::Emitter::Base;
# ABSTRACT: Base class for Data::Schema::Emitter::*

use 5.010;
use Algorithm::Dependency::Ordered;
use Algorithm::Dependency::Source::HoA;
use Any::Moose;
use Data::Dumper;
use Language::Expr;
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

=head2 var_enumer

Language::Expr::VarEnumer object. Used to find out which variables are mentioned
in an expression, to determine the order of attribute processing.

=cut

has var_enumer => (
    is => 'rw',
    default => sub { Language::Expr::Interpreter::VarEnumer->new });


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

# form dependency list from which attributes are mentioned in expressions

sub _form_deps {
    my ($self, $attrs) = @_;

    my %depends;
    for my $attr (values %$attrs) {
        my $name = $attr->{name};
        my $expr = $attr->{name} eq 'check' ? $attr->{value} :
            $attr->{properties}{expr};
        if (defined $expr) {
            my $vars = $self->var_enumer->eval($expr);
            for (@$vars) {
                /^\w+$/ or die "Invalid variable syntax `$_`, currently only " .
                    "variables in the form of \$attr_name supported";
                $attrs->{$_} or die "Unknown attribute specified in variable " .
                    "`$_`";
            }
            $depends{$name} = $vars;
            for (@$vars) {
                push @{ $attrs->{$_}{depended_by} }, $name;
            }
        } else {
            $depends{$name} = [];
        }
    }
    #$log->tracef("deps: %s", \%depends);
    my $ds = Algorithm::Dependency::Source::HoA->new(\%depends);
    my $ad = Algorithm::Dependency::Ordered->new(source => $ds)
        or die "Failed to set up dependency algorithm";
    my $sched = $ad->schedule_all
        or die "Can't resolve dependencies, please check your expressions";
    #$log->tracef("sched: %s", $sched);
    my %rsched = map
        {@{ $depends{$sched->[$_]} } ? ($sched->[$_] => $_) : ()}
            0..@$sched-1;
    #$log->tracef("deps: %s", \%rsched);
    \%rsched;
}

# also sets attr->{ah} and attr->{order}, as a side effect

sub _sort_attrs {
    my ($self, $attrs) = @_;

    my $deps = $self->_form_deps($attrs);

    my $sorter = sub {
        my $na = $a->{name};
        my $pa;
        if (length($na)) {
            $pa = "attrprio_$na"; $pa = $a->{th}->$pa;
        } else {
            $pa = 0;
        }
        my $nb = $b->{name};
        my $pb;
        if (length($nb)) {
            $pb = "attrprio_$nb"; $pb = $a->{th}->$pb;
        } else {
            $pb = 0;
        }
        ($deps->{$na} // -1) <=> ($deps->{$nb} // -1) ||
        $pa <=> $pb ||
        $a->{ah_idx} <=> $b->{ah_idx} ||
        $a->{name} cmp $b->{name}
    };

    # give order value, according to sorting order
    my $order = 0;
    for (sort $sorter values %$attrs) {
        $_->{order} = $order++;
        $_->{ah} = $attrs;
    }
}

# parse attr_hashes into another hashref ready to be processed. ['NAME' =>
# {order=>..., ah_idx=>..., name=>..., value=>..., properties=>{...}, ah=>...,
# type=>..., th=>...}, ...]. each value already contains parsed name, 'value',
# and 'properties'. 'order' is the processing order (1, 2, 3, ...). 'ah_idx' is
# the index to the original attribute hash. 'ah' contains reference to the new
# parsed attribute hash, 'type' contains the type name, and 'th' contains the
# type handler object.

sub _parse_attr_hashes {
    my ($self, $attr_hashes, $type, $th) = @_;
    my %attrs; # key = name#index or name (if index==1) or '' (empty string)

    for my $i (0..@$attr_hashes-1) {
        my $ah = $attr_hashes->[$i];
        for my $k (keys %$ah) {
            my $v = $ah->{$k};
            my ($name, $prop, $expr);
            if ($k =~ /^([_A-Za-z]\w*)?(?:\.?([_A-Za-z]\w*)?|(=))$/) {
                ($name, $prop, $expr) = ($1, $2, $3, $4);
                if ($expr) { $prop = "expr" } else { $prop //= "" }
            } elsif ($k =~ /^\.([_A-Za-z]\w*)$/) {
                $name = '';
                $prop = $1;
            } else {
                die "Invalid attribute syntax: $k, ".
                    "use NAME(.PROP|=)? or .PROP";
            }

            next if $name =~ /^_/ || $prop =~ /^_/;
            if (length($name) && !$th->is_attr($name)) {
                die "Unknown attribute for $type: $name";
            }
            my $key = $name .
                    (@$attr_hashes > 1 ? "#$i" : "");
            my $attr;
            if (!$attrs{$key}) {
                $attr = {ah_idx=>$i, name=>$name,
                         type=>$type, th=>$th};
                $attrs{$key} = $attr;
            } else {
                $attr = $attrs{$key};
            }
            if (length($prop)) {
                $attr->{properties} //= {};
                $attr->{properties}{$prop} = $v;
            } else {
                $attr->{value} = $v;
            }
        }
    }

    $attrs{SANITY} = {ah_idx=>-1, name=>"SANITY",
                      type=>$type, th=>$th};

    $self->_sort_attrs(\%attrs);

    #use Data::Dump; dd map {($_ => {order=>$attrs{$_}{order}, name=>$attrs{$_}{name}, value=>$attrs{$_}{value}})} keys %attrs;

    \%attrs;
}

=head2 emit($schema)

Emit schema into final format. Call _emit() which does the real work.

=cut

sub emit {
    my ($self, $schema) = @_;
    $self->_emit($schema);
}

=head2 emit($schema, $inner, $met_types)

Emit schema into final format. $inner is set to 0 for the first time (by emit())
and set to 1 for inner/recursive emit process. $met_types is XXX.

_emit() will at various points call other methods (hooks) which must be
supplied/added by the subclass (or by the emitter's type handler). These hooks
will be called with hash arguments and expected to return a hash or some other
result. Inside the hook, you can modify the 'result' attribute (e.g. adding a
line to it) or modify some state, etc.

These hooks, in calling order, are:

=over 4

=item * $emitter->on_start(schema=>$schema, inner => 0|1) => ANY|HASH

The base class already does something: reset 'result' to [] (array of lines
containing zero lines).

In Perl emitter, for example, this hook is also used to add 'sub NAME {' and some
'use' statements.

It can return a hash with this key: SKIP_EMIT which if its value set to true then
will end the whole emitting process. In Perl emitter, for example, this is used
to skip re-emitting schema (sub { ... }) that has been defined before.

=item * $emitter->def(name => $name, def => $def, optional => 1|0) => ANY

If the schema contain a subschema definition, this hook will be called for each
definition. B<optional> will be set to true if the definition is an optional one
(e.g. {def => {'?Email' => ...}, ...}).

This hook is actually already defined by this base class, what it does is
register the schema using $ds->register_schema() so it can later be recognized as
a type. Defining a builtin type is not allowed.

=item * $emitter->before_all_attrs(attrs => $attrs) => ANY|HASH

Called before calling handler for any attribute. $attrs is a hashref containing
the list of attributes to process (from all attribute hashes [already merged],
already sorted by priority, name and properties already parsed).

Currently this hook is not used by the Perl emitter, but it can be used, for
example, to rearrange the attributes or emit some preparation code.

It can return a hash with key: SKIP_ALL_ATTRS which if its value set to true will
cause emitting all attributes to be skipped (all the before_attr(), attr_NAME(),
and after_attr() described below will be skipped).

=item * $emitter->before_attr(attr => $attr, th=>$th) => ANY|HASH

Called for each attribute, before calling the actual attribute handler
($th->attr_NAME()). $th is the reference to type handler object.

The Perl emitter, for example, uses this to output a comment containing the
attribute information.

Can return a hash containing these keys: SKIP_THIS_ATTR which if its value set to
true will cause skipping the attribute (attr_NAME() and after_attr());
SKIP_REMAINING_ATTRS which if its value set to true will cause emitting the rest
of the attributes to be skipped (including current attribute's attr_NAME() and
after_attr()).

=item * $th->before_attr(attr => $attr) => ANY|HASH

After emitter's before_attr() is called, type handler's before_attr() will also
be called if available (Note that this method is called on the emitter's type
handler class, not the emitter class itself.)

Input and output interpretation is the same as emitter's before_attr().

=item * $th->attr_NAME(attr => $attr) => ANY|HASH

Note that this method is called on the emitter's type handler class, not the
emitter class itself. NAME is the name of the attribute.

Can return a hash containing key: SKIP_REMAINING_ATTRS which if its value set to
true will cause emitting the rest of the attributes to be skipped (including
current attribute's after_attr()).

=item * $th->after_attr(attr => $attr, attr_res => $res) => ANY|HASH

Note that this method is called on the emitter's type handler class, not the
emitter class itself. Called for each attribute, after calling the actual
attribute handler ($th->attr_NAME()). $res is result return by attr_NAME().

Can return a hash containing key: SKIP_REMAINING_ATTRS which if its value set to
true will cause emitting the rest of the attributes to be skipped.

=item * $emitter->after_attr(attr => $attr, attr_res=>$res, th=>$th) => ANY|HASH

Called for each attribute, after calling the actual attribute handler
($th->attr_NAME()). $res is result return by attr_NAME(). $th is reference to
type handler object.

Output interpretation is the same as $th->after_attr().

=item * $emitter->after_all_attrs(attrs => $attrs) => ANY

Called after all attributes have been emitted.

=item * $emitter->on_end(schema => $schema, inner => 0|1) => ANY

Called at the very end before emitting process end.

The base class' implementation is to join the 'result' attribute's lines into a
single string.

The Perl emitter, for example, also add the enclosing '}' after in on_start() it
emits 'sub { ...'.

=back

=cut

sub _emit {
    my ($self, $schema, $inner, $met_types) = @_;
    $met_types //= [];
    $log->tracef("Entering _emit(schema = %s, inner = %s, met_types = %s)", $schema, $inner, $met_types);

    my $main = $self->main;
    $schema = $main->normalize_schema($schema);
    $log->tracef("Normalized schema, result=%s", $schema);
    die "Can't normalize schema: $schema" unless ref($schema);

    my $on_start_result;
    $log->tracef("Calling on_start()");
    $on_start_result = $self->on_start(schema => $schema, inner => $inner);

    if (ref($on_start_result) eq 'HASH') {
        goto FINISH2 if $on_start_result->{SKIP_EMIT};
    }

    my $saved_types;
    if (keys %{ $schema->{def} }) {
        # since def introduce new schemas into the system, we need to
        # save the original type list first and restore when this
        # schema is out of scope.
        $saved_types = { %{$main->type_names} };

        for my $name (keys %{ $schema->{def} }) {
            my $optional = $name =~ s/^[?]//;
            die "Invalid name in def: $name" unless $name =~ /^\w+$/;
            my $def = $schema->{def}{$name};
            $log->tracef("Calling def(name => %s, def => %s)", $name, $def);
            $self->def(name => $name, def => $def, optional => $optional);
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

    my $attrs = $self->_parse_attr_hashes($attr_hashes, $type, $th);

    if ($th->can("before_all_attrs")) {
        $log->tracef("Calling before_all_attrs()");
        my $res = $th->before_all_attrs(attrs => $attrs);
        if (ref($res) eq 'HASH' && $res->{SKIP_ALL_ATTRS}) { goto FINISH }
    }

  ATTR:
    for my $attr (sort {$a->{order} <=> $b->{order}} values %$attrs) {

        # empty attribute only contain properties
        next unless length($attr->{name});

        if ($self->can("before_attr")) {
            $log->tracef("Calling emitter's before_attr()");
            my $res = $self->before_attr(attr => $attr, th=>$th);
            if (ref($res) eq 'HASH') {
                if ($res->{SKIP_THIS_ATTR}) { next ATTR }
                if ($res->{SKIP_REMAINING_ATTRS}) { goto FINISH }
            }
        }

        if ($th->can("before_attr")) {
            $log->tracef("Calling type handler's before_attr()");
            my $res = $th->before_attr(attr => $attr);
            if (ref($res) eq 'HASH') {
                if ($res->{SKIP_THIS_ATTR}) { next ATTR }
                if ($res->{SKIP_REMAINING_ATTRS}) { goto FINISH }
            }
        }

        my $meth = "attr_$attr->{name}";
        my $attr_res;
        if ($th->can($meth)) {
            $log->tracef("Calling %s(attr: %s=%s)", $meth,
                         $attr->{name}, $attr->{value});
            $attr_res = $th->$meth(attr => $attr);
            if (ref($attr_res) eq 'HASH') {
                if ($attr_res->{SKIP_REMAINING_ATTRS}) { goto FINISH }
            }
        } else {
            die sprintf("Type handler (%s) doesn't have method %s()", ref($th), $meth)
                if $attr->{req};
        }

        if ($th->can("after_attr")) {
            $log->tracef("Calling type handler's before_attr()");
            my $res = $th->after_attr(attr=>$attr, attr_res=>$attr_res);
            if (ref($res) eq 'HASH') {
                if ($res->{SKIP_REMAINING_ATTRS}) { goto FINISH }
            }
        }

        if ($self->can("after_attr")) {
            $log->tracef("Calling emitter's before_attr()");
            my $res = $self->after_attr(attr=>$attr, attr_res=>$attr_res, th=>$th);
            if (ref($res) eq 'HASH') {
                if ($res->{SKIP_REMAINING_ATTRS}) { goto FINISH }
            }
        }

    }

    if ($th->can("after_all_attrs")) {
        $log->tracef("Calling after_all_attrs()");
        $th->after_all_attrs(attrs => $attrs);
    }

  FINISH:

    $main->type_names($saved_types) if $saved_types;

    $log->tracef("Calling on_end()");
    $self->on_end(schema => $schema, inner=>$inner);

  FINISH2:

    $log->trace("Leaving _emit()");
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
    my $optional = $args{optional};
    if ($tn->{$name}) {
        if ($optional) {
            $log->tracef("Not redefining already-defined schema/type `$name`");
            return;
        }
        die "Replacing builtin type currently not allowed ($name)" if !ref($tn->{$name});
        delete $tn->{$name};
    }
    $main->register_schema($def, $name);
}

sub on_start {
    my ($self, %args) = @_;
    # use array of lines
    $self->result([]) unless $args{inner};
}

sub on_end {
    my ($self, %args) = @_;
    # join into final string
    $self->result(join("\n", @{ $self->result }) . "\n") unless $args{inner};
}

sub before_attr {
}

sub after_attr {
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
