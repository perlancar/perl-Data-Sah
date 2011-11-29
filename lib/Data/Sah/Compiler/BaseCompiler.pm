package Data::Sah::Compiler::Base;

use 5.010;
use Moo;
use Log::Any qw($log);

has main => (is => 'rw');
has result => (is => 'rw');
has state => (is => 'rw');
has state_stack => (is => 'rw', default => sub { [] });
has var_enumer => (is => 'rw');
has type_handlers => (is => 'rw', default => sub { {} });
has func_handlers => (is => 'rw', default => sub { {} });

sub name {
    die "Please override name()";
}

sub _die {
    my ($self, $msg) = @_;
    die "Sah ". $self->name . " compiler: $msg";
}

sub get_type_handler {
    my ($self, $name) = @_;
    #$log->trace("-> get_type_handler($name)");
    return $self->type_handlers->{$name} if $self->type_handlers->{$name};

    no warnings;
    $self->_die("Invalid syntax for type name '$name', please use ".
                    "$Data::Sah::type_re")
        unless $name =~ $Data::Sah::type_re;
    my $main = $self->main;
    if ($main->types->{$name}) {
    }
    my $module = ref($self) . "::Type::$name";
    if (!eval "require $module; 1") {
        $self->_die("Can't load type handler $module".($@ ? ": $@" : ""));
    }

    my $obj = $module->new(compiler => $self);
    $self->type_handlers->{$name} = $obj;

    #$log->trace("<- get_type_handler($module)");
    return $obj;
}

sub get_func_handler {
    my ($self, $name) = @_;
    #$log->trace("-> get_func_handler($name)");
    return $self->func_handlers->{$name} if $self->func_handlers->{$name};

    no warnings;
    $self->_die("Invalid syntax for func name `$name`, please use ".
                    "$Data::Sah::func_re")
        unless $name =~ $Data::Sah::func_re;
    my $module = ref($self) . "::Func::$name";
    if (!eval "require $module; 1") {
        $self->_die("Can't load func handler $module".($@ ? ": $@" : ""));
    }

    my $obj = $module->new(compiler => $self);
    $self->func_handlers->{$name} = $obj;

    #$log->trace("<- get_func_handler($module)");
    return $obj;
}

# also sets clause->{cs} and clause->{order}, as a side effect
sub _sort_clauses {
    my ($self, $clauses) = @_;

    my $deps = $self->_form_deps($clauses);

    my $sorter = sub {
        my $na = $a->{name};
        my $pa;
        if (length($na)) {
            $pa = "clauseprio_$na"; $pa = $a->{th}->$pa;
        } else {
            $pa = 0;
        }
        my $nb = $b->{name};
        my $pb;
        if (length($nb)) {
            $pb = "clauseprio_$nb"; $pb = $a->{th}->$pb;
        } else {
            $pb = 0;
        }
        ($deps->{$na} // -1) <=> ($deps->{$nb} // -1) ||
        $pa <=> $pb ||
        $a->{cs_idx} <=> $b->{cs_idx} ||
        $a->{name} cmp $b->{name}
    };

    # give order value, according to sorting order
    my $order = 0;
    for (sort $sorter values %$clauses) {
        $_->{order} = $order++;
        $_->{c} = $clauses;
    }
}

# parse clause_sets (which is an arrayref of clause_set's) into a single hashref
# called clauses, which is ready to be used. {'NAME' => {order=>...,
# cs_idx=>..., name=>..., value=>..., attrs=>{...}, ah=>..., type=>...,
# th=>...}, ...]. each value already contains parsed name, 'value', and 'attrs'.
# 'order' is the processing order (1, 2, 3, ...). 'cs_idx' is the index to the
# original clause_sets arrayref. 'c' contains reference to the new parsed
# clauses, 'type' contains the type name, and 'th' contains the type handler
# object.

sub _parse_clause_sets {
    my ($self, $clause_sets, $type, $th) = @_;
    my %clauses; # key = name#index

    for my $i (0..@$clause_sets-1) {
        my $cs = $clause_sets->[$i];
        for my $k (keys %$cs) {
            my $v = $cs->{$k};
            my ($name, $attr, $expr);
            if ($k =~ /^([_A-Za-z]\w*)?(?::?([_A-Za-z][\w.]*)?|(=))$/) {
                ($name, $attr, $expr) = ($1, $2, $3, $4);
                if ($expr) { $attr = "expr" } else { $attr //= "" }
            } elsif ($k =~ /^\.([_A-Za-z]\w*)$/) {
                $name = '';
                $attr = $1;
            } else {
                die "Invalid clause syntax: $k, ".
                    "use NAME(:ATTR|=)? or :ATTR";
            }

            next if $name =~ /^_/ || $attr =~ /^_/;
            if (length($name) && !$th->is_clause($name)) {
                die "Unknown clause for type `$type`: $name";
            }
            my $key = "$name#$i";
            my $clause;
            if (!$clauses{$key}) {
                $clause = {cs_idx=>$i, name=>$name,
                           type=>$type, th=>$th};
                $clauses{$key} = $clause;
            } else {
                $clause = $clauses{$key};
            }
            if (length($clause)) {
                $clause->{attrs} //= {};
                $clause->{attrs}{$attr} = $v;
            } else {
                $clause->{value} = $v;
            }
        }
    }

    $clauses{SANITY} = {cs_idx=>-1, name=>"SANITY",
                        type=>$type, th=>$th};

    $self->_sort_clauses(\%clauses);

    #use Data::Dump; dd \%clauses;

    \%clauses;
}

sub compile {
    my ($self, %args) = @_;
    $self->_compile(%args);
}

1;
# ABSTRACT: Base class for Sah compilers (Data::Sah::Compiler::*)

=head1 ATTRIBUTES

=head2 main => OBJ

Reference to the main Sah module.

=head2 state => HASHREF

State data when doing compilation, including 'result' (current result), 'lang'
(current language), 'prefilters', 'postfilters'.

=head2 state_stack => ARRAYREF

When doing inner stuffs, state might be saved into the stack first, temporarily
emptied, then restored.

=head2 type_handlers => HASHREF

A hashref of type names and type handlers.

=head2 func_handlers => HASHREF

A hashref of fully qualified func names and func handlers.

=head2 var_enumer => OBJ

Language::Expr::VarEnumer object. Used to find out which variables are mentioned
in an expression, to determine the order of clause processing.


=head1 METHODS

=head2 new() => OBJ

=head2 $c->get_func_handler($fqname) => OBJ

Get func handler for a fully qualified Sah func name (e.g. 'Core::abs'). Dies if
func name is unknown or an error happened. Func handlers live in
Data::Sah::Compiler::<COMPILER_NAME>::FSH::<SET_NAME>. This is mostly used
internally.

=head2 $c->get_type_handler($tname) => OBJ

Get type handler for a type name (e.g. 'int'). Dies if type is unknown or an
error happened. Type handlers live in
Data::Sah::Compiler::<COMPILER_NAME>::TH::<TYPE_NAME>. This is mostly used
internally.

=head2 $c->compile(%args) => STR

Compile schema into target language. Call _compile() which does the real work.

=head2 $c->_compile(%args)

Compile schema into target language (actual code).

Arguments (subclass may introduce others):

=over 4

=item * inputs => ARRAYREF

A list of inputs. Each input is a hashref with the following keys: B<schema>.
Subclasses may require/recognize additional keys (for example, ProgBase
compilers recognize C<data_term> to customize variable to get data from).

=back

_compile() will at various points call other methods (hooks) which must be
supplied/added by the subclass (or by the compiler's type handler). These hooks
will be called with hash arguments and expected to return a hash or some other
result. Inside the hook, you can also modify various B<state>.

These hooks, in calling order, are:

=over 4

=item * $c->on_start(args=>\%args) => HASHREF

Called once at the beginning. B<args> is arguments given to compile().

The base compiler class already does something: set initial B<state>.

The subclasses also usually initialize state here, e.g. the BaseProg subclass
initialize list of defined variables and subroutines.

The return hashref value can contain this key: SKIP_COMPILE which if its value
set to true then will end the whole compilation process. This can be used, for
example, to skip recompiling a schema () that has been compiled before (unless
forced is set to true)

=item * $c->on_start_input(input=>$input) => HASHREF

Called at the start of processing each input. The return hashref value can
contain this key: SKIP_COMPILE which if its value set to true then will end the
whole compilation process. This can be used, for example, to skip recompiling a
schema () that has been compiled before (unless forced is set to true)

=item * $c->def(name => $name, def => $def, optional => 1|0) => HASH

If the schema contain a subschema definition, this hook will be called for each
definition. B<optional> will be set to true if the definition is an optional one
(e.g. {def => {'?Email' => ...}, ...}).

This hook is actually already defined by this base class, what it does is
register the schema using $ds->register_schema() so it can later be recognized as
a type. Defining a builtin type is not allowed.

=item * $compiler->before_all_clauses(clauses => $clauses) => HASH

Called before calling handler for any clauses. $clauses is a hashref containing
the list of clauses to process (from all clause sets [already merged], already
sorted by priority, name and clause attributes already parsed).

Currently this hook is not used by the Perl emitter, but it can be used, for
example, to rearrange the clauses or emit some preparation code.

It returns a hash which can contain a key: SKIP_ALL_CLAUSES which if its value
set to true will cause emitting all clauses to be skipped (all the
before_clause(), clause_NAME(), and after_clause() described below will be
skipped).

=item * $compiler->before_clause(clause => $clause, th=>$th) => HASH

Called for each clause, before calling the actual clause handler
($th->clause_NAME()). $th is the reference to type handler object.

The Perl emitter, for example, uses this to output a comment containing the
clause information.

Return a hash containing which can contain these keys: SKIP_THIS_CLAUSE which if
its value set to true will cause skipping the clause (clause_NAME() and
after_clause()); SKIP_REMAINING_CLAUSES which if its value set to true will
cause emitting the rest of the clauses to be skipped (including current clause's
clause_NAME() and after_clause()).

=item * $th->before_clause(clause => $clause) => HASH

After emitter's before_clause() is called, type handler's before_clause() will
also be called if available (Note that this method is called on the emitter's
type handler class, not the emitter class itself.)

Input and output interpretation is the same as emitter's before_clause().

=item * $th->clause_NAME(clause => $clause) => HASH

Note that this method is called on the emitter's type handler class, not the
emitter class itself. NAME is the name of the clause.

Return a hash which can contain this key: SKIP_REMAINING_CLAUSES which if its
value set to true will cause emitting the rest of the clauses to be skipped
(including current clause's after_clause()).

=item * $th->after_clause(clause => $clause, clause_res => $res) => HASH

Note that this method is called on the emitter's type handler class, not the
emitter class itself. Called for each clause, after calling the actual clause
handler ($th->clause_NAME()). $res is result return by clause_NAME().

Return a hash which can contain this key: SKIP_REMAINING_CLAUSES which if its
value set to true will cause emitting the rest of the clauses to be skipped.

=item * $compiler->after_clause(clause => $clause, clause_res=>$res, th=>$th) => ANY

Called for each clause, after calling the actual clause handler
($th->clause_NAME()). $res is result return by clause_NAME(). $th is reference
to type handler object.

Output interpretation is the same as $th->after_clause().

=item * $compiler->after_all_clauses(clauses => $clauses) => HASH

Called after all clause have been emitted.

=item * $compiler->on_end(schema => $schema, inner => 0|1) => HASH

Called at the very end before emitting process end.

The base class' implementation is to join the 'result' clause's lines into a
single string.

The Perl emitter, for example, also add the enclosing '}' after in on_start() it
emits 'sub { ...'.

=back

=cut

sub _compile {
    my ($self, %args) = @_;
    $log->tracef("-> _compile(%s)", \%args);

    # XXX schema
    my $inputs = $args{inputs} or $self->_die("Please specify inputs");

    $log->tracef("=> on_start()");
    my $os_res = $self->on_start(args => \%args);
    goto FINISH1 if $os_res->{SKIP_COMPILE};

    my $main = $self->main;
    my $i = 0;
    my %saved_types;

  INPUT:
    for my $input (@$inputs) {
        $log->tracef("input=%s", $input);

        $log->tracef("=> on_start_input()");
        my $osi_res = $self->on_start_input(input => $input);
        next INPUT if $osi_res->{SKIP_INPUT};
        goto FINISH1 if $osi_res->{SKIP_COMPILE};

        my $schema = $input->{schema} or $self->_die("Input #$i: No schema");
        $schema = $main->normalize_schema($schema);
        $log->tracef("normalized schema, result=%s", $schema);

        if (keys %{ $schema->{def} }) {
            # since def introduce new schemas into the system, we need to
            # save the original type list first and restore when this
            # schema is out of scope.
            %saved_types = %{$main->types};

            for my $name (keys %{ $schema->{def} }) {
                my $optional = $name =~ s/^[?]//;
                $self->_die("Invalid syntax in def: '$name'")
                    unless $name =~ $Data::Sah::type_re;
                my $def = $schema->{def}{$name};
                $log->tracef("=> def(name => %s, def => %s)", $name, $def);
                my $res = $self->def(
                    name => $name, def => $def, optional => $optional);
            }
        }

        $i++;
    }

    my $type = $schema->{type};
    my $th0 = $self->get_type_handler($type);

    if (ref($th0) eq 'HASH') {
        $log->tracef("Schema is defined in terms of another schema: $type");
        die "Recursive definition: " . join(" -> ", @$met_types) . " -> $type"
            if grep { $_ eq $type } @$met_types;
        push @{ $met_types }, $type;
        $self->_emit({ type => $th0->{type},
                       clause_sets => [@{ $th0->{clause_sets} },
                                       @{ $schema->{clause_sets} }],
                       def => $th0->{def} }, "inner", $met_types);
        goto FINISH;
    }

    #local $self->states->{lang} = ($self->states->{lang} // ($ENV{LANG} && $ENV{LANG} =~ /^(\w{2})/ ? $1 : undef) // "en");
    #local $self->states->{prefilters}  = ($self->states->{prefilters}  ? [@{$self->states->{prefilters}}]  : []);
    #local $self->states->{postfilters} = ($self->states->{postfilters} ? [@{$self->states->{postfilters}}] : []);
    #local $self->states->{level} = ($self->states->{level} // "error");

    $log->tracef("Getting type handler for type %s", $type);
    my $th = $self->get_type_handler($type);
    die "Compiler ".ref($self)." can't handle type `$type` yet" unless $th;

    my $clause_sets = $schema->{clause_sets};
    if (@$clause_sets > 1) {
        $log->tracef("Merging clause_sets: %s", $clause_sets);
        my $res = $main->merge_clause_sets($clause_sets);
        $log->tracef("Merge result: %s", $res);
        die "Can't merge clause sets: $res->{error}" unless $res->{success};
        $clause_sets = $res->{result};
    }

    my $clauses = $self->_parse_clause_sets($clause_sets, $type, $th);

    if ($th->can("before_all_clauses")) {
        $log->tracef("Calling before_all_clauses()");
        my $res = $th->before_all_clauses(clauses => $clauses);
        if ($res->{SKIP_ALL_CLAUSES}) { goto FINISH }
    }

  CLAUSE:
    for my $clause (sort {$a->{order} <=> $b->{order}} values %$clauses) {

        # empty clause only contain attributes
        next unless length($clause->{name});

        if ($self->can("before_clause")) {
            $log->tracef("Calling compiler's before_clause()");
            my $res = $self->before_clause(clause => $clause, th=>$th);
            if ($res->{SKIP_THIS_CLAUSE}) { next CLAUSE }
            if ($res->{SKIP_REMAINING_CLAUSES}) { goto FINISH }
        }

        if ($th->can("before_clause")) {
            $log->tracef("Calling type handler's before_clause()");
            my $res = $th->before_clause(clause => $clause);
            if ($res->{SKIP_THIS_CLAUSE}) { next CLAUSE }
            if ($res->{SKIP_REMAINING_CLAUSES}) { goto FINISH }
        }

        my $meth = "clause_$clause->{name}";
        my $clause_res;
        if ($th->can($meth)) {
            $log->tracef("Calling %s(clause: %s=%s)", $meth,
                         $clause->{name}, $clause->{value});
            $clause_res = $th->$meth(clause => $clause);
            if ($clause_res->{SKIP_REMAINING_CLAUSES}) { goto FINISH }
        } else {
            die sprintf("Type handler (%s) doesn't have method %s()",
                        ref($th), $meth) if $clause->{req};
        }

        if ($th->can("after_clause")) {
            $log->tracef("Calling type handler's after_clause()");
            my $res = $th->after_clause(clause=>$clause,
                                        clause_res=>$clause_res);
            if ($res->{SKIP_REMAINING_CLAUSES}) { goto FINISH }
        }

        if ($self->can("after_clause")) {
            $log->tracef("Calling compiler's after_clause()");
            my $res = $self->after_clause(clause=>$clause,
                                          clause_res=>$clause_res, th=>$th);
            if ($res->{SKIP_REMAINING_CLAUSES}) { goto FINISH }
        }

    }

    if ($th->can("after_all_clauses")) {
        $log->tracef("Calling after_all_clauses()");
        $th->after_all_clauses(clauses => $clauses);
    }

  FINISH:

    $main->type_names($saved_types) if $saved_types;

    $log->tracef("Calling on_end()");
    $self->on_end(schema => $schema, inner=>$inner);

  FINISH2:

    $log->trace("<- _compile()");
    $self->states->{result};
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
    my $st = $self->state_stack;
    unless ($self->state) {
        my $state = {};
        $state->{result} = [];
        $state->{lang} =
            (@$st ? $st->[-1]{lang} : undef) //
                ($ENV{LANG} && $ENV{LANG} =~ /^(\w{2})/ ? $1 : undef) //
                    "en";
        $state->{prefilters} =
            (@$st ? $st->[-1]{prefilters} : undef) //
                [];
        $state->{postfilters} =
            (@$st ? $st->[-1]{postfilters} : undef) //
                [];
        $state->{err_level} =
            (@$st ? $st->[-1]{err_level} : undef) //
                "error";
        $self->state($state);
    }

    {};
}

sub on_end {
    my ($self, %args) = @_;
    # join into final string
    $self->result(join("\n", @{ $self->result }) . "\n") unless $args{inner};
    {};
}

sub before_clause {
    {};
}

sub after_clause {
    {};
}

1;
