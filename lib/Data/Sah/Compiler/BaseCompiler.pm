package Data::Sah::Compiler::Base;

use 5.010;
use Moo;
use Log::Any qw($log);
use Scalar::Util qw(blessed);
use vars qw ($AUTOLOAD);

has main => (is => 'rw');

sub name {
    die "Please override name()";
}

sub _die {
    my ($self, $msg) = @_;
    die "Sah ". $self->name . " compiler: $msg";
}

# parse a schema's clause_sets (which is an arrayref of clause_set's) into
# clauses table.

sub _parse_clause_sets {
    my ($self, $css, $type, $th) = @_;
    my %ct; # key = name#index

    for my $i (0..@$css-1) {
        my $cs = $css->[$i];
        for my $cn0 (keys %$cs) {
            my $cv = $cs->{$cn0};
            my ($name, $attr, $expr);
            if ($cn0 =~ /^([_A-Za-z]\w*)?(?::?([_A-Za-z][\w.]*)?|(=))$/) {
                ($name, $attr, $expr) = ($1, $2, $3, $4);
                if ($expr) { $attr = "expr" } else { $attr //= "" }
            } elsif ($cn0 =~ /^:([_A-Za-z]\w*)$/) {
                $name = '';
                $attr = $1;
            } else {
                $log->_die("Invalid clause name syntax: $cn0, ".
                               "use NAME(:ATTR|=)? or :ATTR");
            }

            next if $name =~ /^_/ || $attr =~ /^_/;
            if (blessed $th) {
                if (length($name) && !$th->is_clause($name)) {
                    $self->_die("Unknown clause for type `$type`: $name");
                }
            }
            my $key = "$name#$i";
            my $cr; # clause record
            if (!$ct{$key}) {
                $cr = {cs_idx=>$i, cs=>$cs, name=>$name};
                $ct{$key} = $cr;
            } else {
                $cr = $ct{$key};
            }
            if (length($attr)) {
                $cr->{attrs} //= {};
                $cr->{attrs}{$attr} = $cv;
            } else {
                $cr->{value} = $cv;
            }
        }
    }

    $ct{SANITY} = {cs_idx=>-1, name=>"SANITY", cs=>undef};

    $self->_sort_clausest(\%ct);
    #use Data::Dump; dd \%ct;

    \%ct;
}

# check a normalized schema for an expression in one of its clauses. this can be
# used to skip calculating expression dependencies when none of schema's clauses
# has expressions.
sub _nschema_has_expr {
    my ($self, $ns) = @_;
    for my $cs (@{$ns->{clause_sets}}) {
        return 1 if defined $cs->{check};
        for my $c (keys %$cs) {
            return 1 if $c =~ /(?::expr|=)$/;
        }
    }
    0;
}

# like _nschema_has_expr(), but check a clauses table instead.
sub _clausest_has_expr {
    my ($self, $ct) = @_;
    for my $cr (@$ct) {
        return 1 if $cr->{attrs}{expr};
    }
    0;
}

# sort clauses table in-place, based on priority and expression dependencies.
# also sets each clause record's 'order' key as side effect.
sub _sort_clausest {
    my ($self, $ct) = @_;

    my $deps;
    if ($self->_clausest_has_expr($ct)) {
        $deps = $self->_form_deps($ct);
    } else {
        $deps = {};
    }

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
    for (sort $sorter values %$ct) {
        $_->{order} = $order++;
    }
}

sub _get_th {
    my ($self, %args) = @_;
    my $cdata = $args{cdata};
    my $name  = $args{name};

    my $th_table = $cdata->{th_table};
    return $th_table->{$name} if $th_table->{$name};

    if ($args{load} // 1) {
        no warnings;
        $self->_die("Invalid syntax for type name '$name', please use ".
                        "$Data::Sah::type_re")
            unless $name =~ $Data::Sah::type_re;
        my $main = $self->main;
        my $module = ref($self) . "::Type::$name";
        if (!eval "require $module; 1") {
            $self->_die("Can't load type handler $module".
                            ($@ ? ": $@" : ""));
        }

        my $obj = $module->new();
        $th_table->{$name} = $obj;
    }

    return $th_table->{$name};
}

sub get_fsh {
    my ($self, %args) = @_;
    my $cdata = $args{cdata};
    my $name  = $args{name};

    my $fsh_table = $cdata->{fsh_table};
    return $fsh_table->{$name} if $fsh_table->{$name};

    if ($args{load} // 1) {
        no warnings;
        $self->_die("Invalid syntax for func set name `$name`, please use ".
                        "$Data::Sah::funcset_re")
            unless $name =~ $Data::Sah::funcset_re;
        my $module = ref($self) . "::FSH::$name";
        if (!eval "require $module; 1") {
            $self->_die("Can't load func set handler $module".
                            ($@ ? ": $@" : ""));
        }

        my $obj = $module->new();
        $fsh_table->{$name} = $obj;
    }

    return $fsh_table->{$name};
}

sub compile {
    my ($self, %args) = @_;
    $self->_compile(%args);
}

sub _compile {
    my ($self, %args) = @_;
    $log->tracef("-> _compile(%s)", \%args);

    # XXX schema
    my $inputs = $args{inputs} or $self->_die("Please specify inputs");
    ref($inputs) eq 'ARRAY' or $self->_die("inputs must be an array");

    $log->tracef("=> before_compile()");
    my $bc_res = $self->before_compile(args=>$args);
    my $cdata = $bc_res->{cdata}
        or $self->_die("before_compile hook didn't return cdata");
    goto SKIP_ALL_INPUTS if $bc_res->{SKIP_ALL_INPUTS};

    my $main = $self->main;
    my $i = 0;

  INPUT:
    for my $input (@$inputs) {

        $log->tracef("input=%s", $input);
        $cdata->{input} = $input;

        $log->tracef("=> before_input()");
        my $bi_res = $self->before_input(cdata=>$cdata);
        next INPUT if $bi_res->{SKIP_THIS_INPUT};
        goto SKIP_REMAINING_INPUTS if $bi_res->{SKIP_REMAINING_INPUTS};

        my $schema  = $input->{schema} or $self->_die("Input #$i: No schema");
        my $nschema = $main->normalize_schema($schema);
        $log->tracef("normalized schema, result=%s", $nschema);
        $cdata->{schema} = $nschema;

        $log->tracef("=> before_schema()");
        my $bs_res = $self->before_schema(cdata=>$cdata);
        next SKIP_SCHEMA if $bs_res->{SKIP_SCHEMA};

        if (keys %{ $nschema->{def} }) {
            # since def introduce new schemas into the system, we need to save
            # the original type handlers first and restore when this schema is
            # out of scope.
            %saved_th = %{$self->_th};

            for my $name (keys %{ $nschema->{def} }) {
                my $optional = $name =~ s/^[?]//;
                $self->_die("Invalid name syntax in def: '$name'")
                    unless $name =~ $Data::Sah::type_re;
                my $def = $schema->{def}{$name};
                $log->tracef("=> def(name => %s, def => %s)", $name, $def);
                my $res = $self->def(
                    cdata=>$cdata, name=>$name, def=>$def, optional=>$optional);
            }
        }

        my $tn = $nschema->{type};
        my $th = $self->_get_th(cdata=>$cdata, name=>$tn);
        $cdata->{th} = $th;

        my $css = $nschema->{clause_sets};
        if (@$css > 1) {
            $log->tracef("Merging clause_sets: %s", $css);
            $css = $self->_merge_clause_sets($css);
            $log->tracef("Merge result: %s", $css);
        }

        $log->tracef("Parsing clause sets into clause table ...");
        my $ct = $self->_parse_clause_sets($css, $tn, $th);
        $cdata->{ct} = $ct;

        if ($th->can("before_all_clauses")) {
            $log->tracef("=> before_all_clauses()");
            my $res = $th->before_all_clauses(cdata=>$cdata);
            if ($res->{SKIP_ALL_CLAUSES}) { goto FINISH_INPUT }
        }

      CLAUSE:
        for my $clause (sort {$a->{order} <=> $b->{order}} values %$ct) {
            $cdata->{clause} = $clause;

            # empty clause only contain attributes
            next unless length($clause->{name});

            if ($self->can("before_clause")) {
                $log->tracef("=> compiler's before_clause()");
                my $res = $self->before_clause(cdata=>$cdata);
                if ($res->{SKIP_THIS_CLAUSE}) { next CLAUSE }
                if ($res->{SKIP_REMAINING_CLAUSES}) { goto FINISH_INPUT }
            }

            if ($th->can("before_clause")) {
                $log->tracef("=> type handler's before_clause()");
                my $res = $th->before_clause(cdata);
                if ($res->{SKIP_THIS_CLAUSE}) { next CLAUSE }
                if ($res->{SKIP_REMAINING_CLAUSES}) { goto FINISH_INPUT }
            }

            my $meth = "clause_$c->{name}";
            if ($th->can($meth)) {
                $log->tracef("=> type_handler's %s(clause: %s=%s)", $meth,
                             $c->{name}, $c->{value});
                my $cres = $th->$meth(cdata=>$cdata);
                $cdata->{clause_res} = $cres;
                if ($cres->{SKIP_REMAINING_CLAUSES}) { goto FINISH_INPUT }
            } else {
                $self->_die(
                    sprintf("Type handler (%s) doesn't have method %s()",
                            ref($th), $meth)) if $c->{req};
            }

            if ($th->can("after_clause")) {
                $log->tracef("=> type handler's after_clause()");
                my $res = $th->after_clause(cdata=>$cdata);
                if ($res->{SKIP_REMAINING_CLAUSES}) { goto FINISH_INPUT }
            }

            if ($self->can("after_clause")) {
                $log->tracef("=> compiler's after_clause()");
                my $res = $self->after_clause(cdata=>$cdata);
                if ($res->{SKIP_REMAINING_CLAUSES}) { goto FINISH_INPUT }
            }

        }

        if ($th->can("after_all_clauses")) {
            $log->tracef("=> after_all_clauses()");
            $th->after_all_clauses(cdata=>$cdata);
        }

        $i++;

      FINISH_INPUT:
        $log->tracef("=> after_input()");
        $self->after_input(cdata=>$cdata);

    } # for input


  SKIP_REMAINING_INPUTS:
    $log->tracef("=> after_compile()");
    $self->after_compile(cdata=>$cdata);

  SKIP_ALL_INPUTS:
    $log->trace("<- _compile()");
    $self->states->{result};
}

sub before_compile {
    my ($self, %args) = @_;
    my $outer_cdata = $args{outer_cdata};

    my $cdata = {};
    $cdata->{outer}   = $outer_cdata;
    $cdata->{args}    = $args{args};
    $cdata->{th_map}  = {};
    $cdata->{fsh_map} = {};
    $cdata->{result}  = {};

    {};
}

sub before_schema {
    my ($self, %args) = @_;
    my $cdata = $args{cdata};
    my $outer = $cdata->{outer};

    $cdata->{lang} = $cdata->{lang} //
        ($ENV{LANG} && $ENV{LANG} =~ /^(\w{2})/ ? $1 : undef) //
            "en";
    $cdata->{prefilters}  = $outer->{prefilters} //
        [];
    $cdata->{postfilters} = $outer->{postfilters} //
        [];

    {};
}

sub def {
    my ($self, %args) = @_;
    my $cdata    = $args{cdata};
    my $name     = $args{name};
    my $def      = $args{def};
    my $optional = $args{optional};

    my $th = $self->_get_th(cdata=>$cdata, name=>$name, load=>0);
    if ($th) {
        if ($optional) {
            $log->tracef("Not redefining already-defined schema/type `$name`");
            return;
        }
        $self->_die("Redefining existing type ($name) currently not allowed");
    }

    my $nschema = $self->main->normalize_schema($def);
    $cdata->{th_table}{$name} = $nschema;

    {};
}

sub after_compile {
    {};
}

sub before_clause {
    {};
}

sub after_clause {
    {};
}

sub AUTOLOAD {
    my ($pkg, $sub) = $AUTOLOAD =~ /(.+)::(.+)/;
    die "Undefined subroutine $AUTOLOAD"
        unless $sub =~ /^(
                            _form_deps|
                            _merge_clause_sets
                        )$/x;
    $pkg =~ s!::!/!g;
    require "$pkg/al_$sub.pm";
    goto &$AUTOLOAD;
}

1;
# ABSTRACT: Base class for Sah compilers (Data::Sah::Compiler::*)

=head1 ATTRIBUTES

=head2 main => OBJ

Reference to the main Sah module.


=head1 METHODS

=head2 new() => OBJ

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
will be called with hash arguments and expected to return a hashref. One of the
arguments that will always be passed is B<cdata>, compilation data, which is a
used to store the compilation state and result. It is passed around instead of
put as an attribute to simplify inner compilation (i.e. a hook invokes another
_compile()).

These hooks, in calling order, are:

=over 4

=item * $c->before_compile(args=>\%args, outer_cdata=>$d) => HASHREF

Called once at the beginning of compilation. The base class initializes a
relatively empty compilation data and return it.

Arguments: B<args> (arguments given to _compile()), B<outer_cdata> can be set if
this compilation is for a subschema. This compilation data will then be based on
outer_cdata instead of empty.

Return value: If key SKIP_ALL_INPUTS is set to true then the whole compilation
process will end (after_compile() will not even be called). The return hashref
value MUST also return cdata, as it will be passed around to the remaining
hooks.

About B<compilation data> (B<cdata>): it store schema compilation state, or
other compilation data (like result). Should be a hashref containing these keys
(subclasses may add more data): B<args> (arguments given to _compile()),
B<compiler> (the compiler object), B<result>, B<input> (current input),
B<schema> (current schema we're compiling), B<ct> (clauses table, see
explanation below), B<lang> (current language, a 2-letter code), C<clause>
(current clause), C<th> (current type handler), C<clause_res> (result of clause
handler), B<prefilters> (an array of containing names of current prefilters),
B<postfilters> (an array containing names of postfilters), B<th_map> (a hashref
containing mapping of fully-qualified type names like C<int> and its
Data::Sah::Compiler::*::TH::* type handler object (or a hash form, normalized
schema), B<fsh_map> (a hashref containing mapping of function set name like
C<core> and its Data::Sah::Compiler::*::FSH::* handler object).

About B<clauses table> (sometimes abbreviated as B<ct>): A single hashref
containing all the clauses to be processed, parsed from schema's clause_sets
(which is an array of hashrefs). It is easier to use by the handlers. Each hash
key is clause name, stripped from all prefixes and attributes, in the form of
NAME (e.g. 'min') or NAME#INDEX if there are more than one clause of the same
name (e.g. 'min#1', 'min#2' and so on).

Each hash value is called a B<clause record> which is a hashref: {name=>...,
value=>...., attrs=>{...}, order=>..., cs_idx=>..., cs=>...]. 'name' is the
clause name (no prefixes, attributes, or #INDEX suffixes), 'value' is the clause
value, 'attrs' is a hashref containing attribute names and values, 'order' is
the processing order (1, 2, 3, ...), 'cs_idx' is the index to the original
clause_sets arrayref, 'cs' is reference to the original clause set.

=item * $c->before_input(cdata=>$cdata) => HASHREF

Called at the start of processing each input. Base compiler uses this to
set/reset B<schema>, C<ct>, and the rest of schema data in B<cdata>.

Arguments: B<cdata>.

Return value: If SKIP_THIS_INPUT is set to true then compilation for the current
input ends and compilation moves on to the next input. This can be used, for
example, to skip recompiling a schema that has been compiled before.

=item * $c->before_schema(cdata=>$cdata) => HASHREF

Called at the start of processing each schema. At this stage, the normalized
schema is available at $cdata->{schema}. The base compiler uses this hook to
save $cdata->{th_table_before_def} which is type table before being modified by
any subschema definition.

Arguments: B<cdata>.

Return value: If SKIP_THIS_SCHEMA is set to true then compilation for the
current schema and compilation directly move on to after_input(). This can be
used, for example, to skip recompiling a schema that has been compiled before.

=item * $c->def(cdata=>$d, name=>$name, def=>$def, optional=>1|0) => HASHREF

Called for each subschema definition.

Arguments: B<cdata>, B<name> (definition name), B<def> (the definition),
B<optional> (boolean will be set to true if the definition is an optional one,
e.g. {def => {'?email' => ...}, ...}).

=item * $c->before_all_clauses(cdata=>$d) => HASHREF

Called before calling handler for any clauses.

=item * $c->before_clause(cdata=>$d) => HASHREF

Called for each clause, before calling the actual clause handler
($th->clause_NAME()).

Return value: If SKIP_THIS_CLAUSE is set to true then compilation for the clause
will be skipped (including calling clause_NAME() and after_clause()). If
SKIP_REMAINING_CLAUSES is set to true then compilation for the rest of the
schema's clauses will be skipped (including current clause's clause_NAME() and
after_clause()).

=item * $th->before_clause(cdata=>$d) => HASHREF

After compiler's before_clause() is called, type handler's before_clause() will
also be called if available (note that this method is called on the compiler's
type handler class, not the compiler class itself.)

Input and output interpretation is the same as compiler's before_clause().

=item * $th->clause_NAME(cdata=>$d) => HASHREF

Note that this method is called on the compiler's type handler class, not the
compiler class itself. NAME is the name of the clause.

Return value: If SKIP_REMAINING_CLAUSES if set to true then compilation for the
rest of the clauses to be skipped (including current clause's after_clause()).

=item * $th->after_clause(cdata=>$d) => HASHREF

Note that this method is called on the compiler's type handler class, not the
compiler class itself. Called for each clause, after calling the actual clause
handler ($th->clause_NAME()).

Return value: If SKIP_REMAINING_CLAUSES is set to true then compilation for the
rest of the clauses to be skipped.

=item * $c->after_clause(cdata=>$d) => HASHREF

Called for each clause, after calling the actual clause handler
($th->clause_NAME()). $res is result return by clause_NAME(). B<th> is reference
to type handler object.

Output interpretation is the same as $th->after_clause().

=item * $c->after_all_clauses(cdata=>$d) => HASHREF

Called after all clause have been compiled.

=item * $c->after_input(cdata=>$d) => HASHREF

Called for each input after compiling finishes.

Return hashref which can contain this key: SKIP_REMAINING_INPUTS which if set to
true will skip remaining inputs.

=item * $c->after_compile(cdata=>$d) => HASHREF

Called at the very end before compiling process end.

=back

=cut
