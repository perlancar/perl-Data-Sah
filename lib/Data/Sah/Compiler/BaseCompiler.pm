package Data::Sah::Compiler::BaseCompiler;

use 5.010;
#use Carp;
use Moo;
use Log::Any qw($log);

use Scalar::Util qw(blessed);

# VERSION

has main => (is => 'rw');

# instance to Language::Expr instance
has expr_compiler => (
    is => 'rw',
    lazy => 1,
    default => sub {
        require Language::Expr;
        Language::Expr->new;
    },
);

# can be changed to tab, for example
has indent_character => (is => 'rw', default => sub {''});

sub name {
    die "BUG: Please override name()";
}

# literal representation in target language
sub literal {
    die "BUG: Please override literal()";
}

# compile expression to target language
sub expr {
    die "BUG: Please override _expr()";
}

sub _die {
    my ($self, $cd, $msg) = @_;
    die join(
        "",
        "Sah ". $self->name . " compiler: ",
        defined($cd->{input_num}) ? "Input #$cd->{input_num}: " : "",
        $msg,
    );
}

# form dependency list from which clauses are mentioned in expressions NEED TO
# BE UPDATED: NEED TO CHECK EXPR IN ALL ATTRS, THERE IS NO LONGER A ctbl.
sub _form_deps {
    require Algorithm::Dependency::Ordered;
    require Algorithm::Dependency::Source::HoA;
    require Language::Expr::Interpreter::VarEnumer;

    my ($self, $cd, $ctbl) = @_;
    my $main = $self->main;

    my %depends;
    for my $crec (values %$ctbl) {
        my $cn = $crec->{name};
        my $expr = defined($crec->{expr}) ? $crec->{value} :
            $crec->{attrs}{expr};
        if (defined $expr) {
            my $vars = $main->_var_enumer->eval($expr);
            for (@$vars) {
                /^\w+$/ or $self->_die($cd,
                    "Invalid variable syntax '$_', ".
                        "currently only the form \$abc is supported");
                $ctbl->{$_} or $self->_die($cd,
                    "Unknown clause specified in variable '$_'");
            }
            $depends{$cn} = $vars;
            for (@$vars) {
                push @{ $ctbl->{$_}{depended_by} }, $cn;
            }
        } else {
            $depends{$cn} = [];
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

# since a schema can be based on another schema, we need to resolve to get the
# "base" type's handler (and collect clause sets in the process). for example:
# if pos_int is [int => {min=>0}], and pos_even is [pos_int, {div_by=>2}] then
# resolving pos_even will result in: ["int", [{min=>0}, {div_by=>2}], []]. The
# first element is the base type, the second is merged clause sets, the third is
# merged extras.
sub _resolve_base_type {
    require Scalar::Util;

    my ($self, %args) = @_;
    my $ns   = $args{schema};
    my $t    = $ns->[0];
    $log->tracef("=> _resolve_base_type(%s)", $t);
    my $cd   = $args{cd};
    my $th   = $self->get_th(name=>$t, cd=>$cd);
    my $seen = $args{seen} // {};
    my $res  = $args{res} // [$t, [], []];

    $self->_die($cd, "Recursive dependency on type '$t'") if $seen->{$t}++;

    $res->[0] = $t;
    unshift @{$res->[1]}, $ns->[1] if keys(%{$ns->[1]});
    unshift @{$res->[2]}, $ns->[2] if $ns->[2];
    if (Scalar::Util::blessed $th) {
        $res->[1] = $self->main->_merge_clause_sets(@{$res->[1]});
        $res->[2] = $self->main->_merge_clause_sets(@{$res->[2]});
    } else {
        $self->_resolve_base_type(schema=>$th, cd=>$cd, seen=>$seen, res=>$res);
    }
    $res;
}

# sort clause set, based on priority and expression dependencies. return an
# array containing ordered list of clause names.
sub _sort_cset {
    my ($self, $cd, $cset) = @_;
    my $tn = $cd->{type};
    my $th = $cd->{th};

    my $deps;
    ## temporarily disabled, expr needs to be sorted globally
    #if ($self->_cset_has_expr($cset)) {
    #    $deps = $self->_form_deps($ctbl);
    #} else {
    #    $deps = {};
    #}
    $deps = {};

    my $sorter = sub {
        my $res;

        # dependency
        $res = ($deps->{$a} // -1) <=> ($deps->{$b} // -1);
        return $res if $res;

        # prio from clause definition
        my ($metaa, $metab);
        eval {
            $metaa = "Data::Sah::Type::$tn"->${\("clausemeta_$a")};
        };
        $@ and $self->_die($cd, "Unknown clause for type $tn: $a");
        eval {
            $metab = "Data::Sah::Type::$tn"->${\("clausemeta_$b")};
        };
        $@ and $self->_die($cd, "Unknown clause for type $tn: $a");
        $res = $metaa->{prio} <=> $metab->{prio};
        return $res if $res;

        # prio from schema
        my $sprioa = $cset->{"$a.prio"} // 50;
        my $spriob = $cset->{"$b.prio"} // 50;
        $res = $sprioa <=> $spriob;
        return $res if $res;

        $a cmp $b;
    };

    sort $sorter grep {!/\A_/ && !/\./} keys %$cset;
}

sub get_th {
    my ($self, %args) = @_;
    my $cd    = $args{cd};
    my $name  = $args{name};

    my $th_map = $cd->{th_map};
    return $th_map->{$name} if $th_map->{$name};

    if ($args{load} // 1) {
        no warnings;
        $self->_die($cd, "Invalid syntax for type name '$name', please use ".
                        "letters/numbers/underscores only")
            unless $name =~ $Data::Sah::type_re;
        my $main = $self->main;
        my $module = ref($self) . "::TH::$name";
        if (!eval "require $module; 1") {
            $self->_die($cd, "Can't load type handler $module".
                            ($@ ? ": $@" : ""));
        }

        my $obj = $module->new(compiler=>$self);
        $th_map->{$name} = $obj;
    }

    return $th_map->{$name};
}

sub get_fsh {
    my ($self, %args) = @_;
    my $cd    = $args{cd};
    my $name  = $args{name};

    my $fsh_table = $cd->{fsh_table};
    return $fsh_table->{$name} if $fsh_table->{$name};

    if ($args{load} // 1) {
        no warnings;
        $self->_die($cd, "Invalid syntax for func set name '$name', ".
                        "please use letters/numbers/underscores")
            unless $name =~ $Data::Sah::funcset_re;
        my $module = ref($self) . "::FSH::$name";
        if (!eval "require $module; 1") {
            $self->_die($cd, "Can't load func set handler $module".
                            ($@ ? ": $@" : ""));
        }

        my $obj = $module->new();
        $fsh_table->{$name} = $obj;
    }

    return $fsh_table->{$name};
}

sub init_cd {
    my ($self, %args) = @_;

    my $outer_cd = $args{outer_cd};
    my $cd = $outer_cd ? { %$outer_cd, outer_cd=>$outer_cd } : {};
    $cd->{args}         = \%args;
    $cd->{th_map}     //= {};
    $cd->{fsh_map}    //= {};
    $cd->{result}     //= [];
    $cd->{indent_level} //= 0;
    $cd->{default_lang} = $cd->{lang} // $ENV{LANG} // "en_US";
    $cd->{default_lang} =~ s/\..+//; # en_US.UTF-8 -> en_US

    $cd;
}

sub _check_compile_args {
    state $checked; return if $checked++;

    my ($self, $args) = @_;

    my %seen;
    my $inputs = $args->{inputs} or $self->_die({}, "Please specify inputs");
    ref($inputs) eq 'ARRAY' or $self->_die({}, "inputs must be an array");
    @$inputs or $self->_die({}, "please specify at least one input in inputs");
    for my $i (0..@$inputs-1) {
        ref($inputs->[$i]) eq 'HASH' or $self->_die(
            {}, "inputs[$i] must be hash");
        defined($inputs->[$i]{name}) or $self->_die(
            {}, "Please specify inputs[$i]{name}");
        $inputs->[$i]{name} =~ /\A[A-Za-z_]\w*\z/ or $self->_die(
            {}, "Invalid syntax in inputs[$i]{name}, ".
                "please use letters/nums only");
        $seen{ $inputs->[$i]{name} } and $self->_die(
            {}, "Duplicate name in inputs[$i]{name} '$inputs->[$i]{name}'");
    }
    $args->{allow_expr} //= 1;
}

sub compile {
    my ($self, %args) = @_;
    $log->tracef("-> compile(%s)", \%args);

    # XXX schema
    $self->_check_compile_args(\%args);

    my $main   = $self->main;
    my $cd     = $self->init_cd(%args);
    my $inputs = $args{inputs};

    if ($self->can("before_compile")) {
        $log->tracef("=> before_compile()");
        $self->before_compile($cd);
        goto SKIP_ALL_INPUTS if delete($cd->{SKIP_ALL_INPUTS});
    }

    my $i = 0;
  INPUT:
    for my $in (@$inputs) {

        my $th_map_before_def;

        $log->tracef("input=%s", $in);
        local $cd->{input}     = $in;
        local $cd->{input_num} = $i;

        if ($self->can("before_input")) {
            $log->tracef("=> before_input()");
            $self->before_input($cd);
            next INPUT if delete $cd->{SKIP_THIS_INPUT};
            goto SKIP_REMAINING_INPUTS if delete $cd->{SKIP_REMAINING_INPUTS};
        }

        my $schema0 = $in->{schema} or $self->_die($cd, "No schema");

        my $nschema;
        if ($in->{normalized}) {
            $nschema = $schema0;
            $log->tracef("schema already normalized, skipped normalization");
        } else {
            $nschema = $main->normalize_schema($schema0);
            $log->tracef("normalized schema, result=%s", $nschema);
        }
        $nschema->[2] //= {};
        local $cd->{schema} = $nschema;

        $th_map_before_def = { %{$cd->{th_map}} };
        {
            my $defs = $nschema->[2]{def};
            if ($defs) {
                for my $name (sort keys %$defs) {
                    my $def = $defs->{$name};
                    my $opt = $name =~ s/[?]\z//;
                    local $cd->{def_optional} = $opt;
                    local $cd->{def_name}     = $name;
                    $self->_die($cd, "Invalid name syntax in def: '$name'")
                        unless $name =~ $Data::Sah::type_re;
                    local $cd->{def_def}      = $def;
                    $self->def($cd);
                    $log->tracef("=> def() name=%s, def=>%s, optional=%s)",
                                 $name, $def, $opt);
                }
            }
        }

        my $res    = $self->_resolve_base_type(schema=>$nschema, cd=>$cd);
        my $tn     = $res->[0];
        my $th     = $self->get_th(name=>$tn, cd=>$cd);
        my $csets  = $res->[1];
        local $cd->{th}   = $th;
        local $cd->{type} = $tn;

        if ($self->can("before_all_clauses")) {
            $log->tracef("=> comp->before_all_clauses()");
            $self->before_all_clauses($cd);
            goto FINISH_INPUT if delete $cd->{SKIP_ALL_CLAUSES};
        }
        if ($th->can("before_all_clauses")) {
            $log->tracef("=> th->before_all_clauses()");
            $th->before_all_clauses($cd);
            goto FINISH_INPUT if delete $cd->{SKIP_ALL_CLAUSES};
        }

      CSET:
        for my $cset (@$csets) {
            #$log->tracef("Processing cset: %s", $cset);
            for (keys %$cset) {
                if (!$args{allow_expr} && /\.is_expr\z/ && $cset->{$_}) {
                    $self->_die($cd, "Expression not allowed: $_");
                }
            }

            local $cd->{cset}  = $cset;
            local $cd->{ucset} = {
                map {$_=>$cset->{$_}}
                    grep { !/\A_|\._/ } keys %$cset };

            my @clauses = $self->_sort_cset($cd, $cset);

            if ($self->can("before_clause_set")) {
                $log->tracef("=> comp->before_clause_set()");
                $self->before_clause_set($cd);
                next CSET if delete $cd->{SKIP_THIS_CLAUSE_SET};
                goto FINISH_INPUT if delete $cd->{SKIP_REMAINING_CLAUSES};
            }
            if ($th->can("before_clause_set")) {
                $log->tracef("=> th->before_clause_set()");
                $th->before_clause_set($cd);
                next CSET if delete $cd->{SKIP_THIS_CLAUSE_SET};
                goto FINISH_INPUT if delete $cd->{SKIP_REMAINING_CLAUSES};
            }

          CLAUSE:
            for my $clause (@clauses) {
                $log->tracef("Processing clause: %s", $clause);
                delete $cd->{ucset}{"$clause.prio"};

                # put information about the clause to $cd

                my $meta = $th->${\("clausemeta_$clause")};;
                local $cd->{cl_meta} = $meta;
                $self->_die($cd, "Clause $clause doesn't allow expression")
                    if $cset->{"$clause.is_expr"} && !$meta->{allow_expr};
                for my $a (keys %{ $meta->{attrs} }) {
                    my $av = $meta->{attrs}{$a};
                    $self->_die($cd, "Attribute $clause.$a doesn't allow ".
                                    "expression")
                        if $cset->{"$clause.$a.is_expr"} && !$av->{allow_expr};
                }
                local $cd->{clause} = $clause;
                my $cv = $cset->{$clause};
                local $cd->{cl_term} = $cset->{"$clause.is_expr"} ?
                    $self->expr($cv) : $self->literal($cv);
                local $cd->{cl_is_expr} = $cset->{"$clause.is_expr"};
                local $cd->{cl_is_multi} = $cset->{"$clause.is_multi"};
                delete $cd->{ucset}{"$clause.is_expr"};
                delete $cd->{ucset}{"$clause.is_multi"};
                delete $cd->{ucset}{$clause};

                if ($self->can("before_clause")) {
                    $log->tracef("=> comp->before_clause()");
                    $self->before_clause($cd);
                    next CLAUSE if delete $cd->{SKIP_THIS_CLAUSE};
                    goto FINISH_INPUT if delete $cd->{SKIP_REMAINING_CLAUSES};
                }
                if ($th->can("before_clause")) {
                    $log->tracef("=> th->before_clause()");
                    $th->before_clause($cd);
                    next CLAUSE if delete $cd->{SKIP_THIS_CLAUSE};
                    goto FINISH_INPUT if delete $cd->{SKIP_REMAINING_CLAUSES};
                }

                my $meth = "clause_$clause";
                $log->tracef("=> type handler's $meth()");
                $th->$meth($cd);
                goto FINISH_INPUT if $cd->{SKIP_REMAINING_CLAUSES};

                if ($th->can("after_clause")) {
                    $log->tracef("=> th->after_clause()");
                    $th->after_clause($cd);
                    goto FINISH_INPUT if $cd->{SKIP_REMAINING_CLAUSES};
                }
                if ($self->can("after_clause")) {
                    $log->tracef("=> comp->after_clause()");
                    $self->after_clause($cd);
                    goto FINISH_INPUT if $cd->{SKIP_REMAINING_CLAUSES};
                }
            } # for clause

            if ($th->can("after_clause_set")) {
                $log->tracef("=> th->after_clause()");
                $th->after_clause_set($cd);
                goto FINISH_INPUT if $cd->{SKIP_REMAINING_CLAUSES};
            }
            if ($self->can("after_clause_set")) {
                $log->tracef("=> comp->after_clause()");
                $self->after_clause_set($cd);
                goto FINISH_INPUT if $cd->{SKIP_REMAINING_CLAUSES};
            }

            if (keys %{$cd->{ucset}}) {
                $self->_die($cd, "Unknown/unprocessed clauses/attributes: ".
                                join(", ", keys %{$cd->{ucset}}));
            }

        } # for cset

        if ($th->can("after_all_clauses")) {
            $log->tracef("=> th->after_all_clauses()");
            $th->after_all_clauses($cd);
        }
        if ($self->can("after_all_clauses")) {
            $log->tracef("=> comp->after_all_clauses()");
            $self->after_all_clauses($cd);
        }

        $i++;

      FINISH_INPUT:
        $cd->{th_map} = $th_map_before_def if $th_map_before_def;

        if ($self->can("after_input")) {
            $log->tracef("=> after_input()");
            $self->after_input($cd);
            goto SKIP_REMAINING_INPUTS if delete $cd->{SKIP_REMAINING_INPUTS};
        }

    } # for input


  SKIP_REMAINING_INPUTS:
    if ($self->can("after_compile")) {
        $log->tracef("=> after_compile()");
        $self->after_compile($cd);
    }

  SKIP_ALL_INPUTS:
    $log->trace("<- compile()");
    return $cd;
}

sub line {
    my ($self, $cd, @args) = @_;
    push @{ $self->result }, join(
        "", $self->indent_character x $cd->{indent_level},
        @args);
    $self;
}

sub def {
    my ($self, $cd) = @_;
    my $name = $cd->{def_name};
    my $def  = $cd->{def_def};
    my $opt  = $cd->{def_optional};

    my $th = $self->get_th(cd=>$cd, name=>$name, load=>0);
    if ($th) {
        if ($opt) {
            $log->tracef("Not redefining already-defined schema/type '$name'");
            return;
        }
        $self->_die($cd, "Redefining existing type ($name) not allowed");
    }

    my $nschema = $self->main->normalize_schema($def);
    $cd->{th_map}{$name} = $nschema;
}

1;
# ABSTRACT: Base class for Sah compilers (Data::Sah::Compiler::*)

=head1 ATTRIBUTES

=head2 main => OBJ

Reference to the main Data::Sah object.

=head2 expr_compiler => OBJ

Reference to expression compiler object. In the perl compiler, for example, this
will be an instance of L<Language::Expr::Compiler::Perl> object.

=head2 indent_character => STR (default: ' ')

Specify indent character used. Can be changed to a tab character, for example,
but most compilers usually work with spaces.


=head1 METHODS

=head2 new() => OBJ

=head2 $c->compile(%args) => HASH

Compile schema into target language.

Arguments (subclass may introduce others):

=over 4

=item * inputs => ARRAY

A list of inputs. Each input is a hashref with the following keys: C<name>
(string, a unique name, should only contain alphanumeric characters), C<schema>,
C<normalized> (bool, set to true if input schema is already normalized to skip
normalization step). Subclasses may require/recognize additional keys (for
example, BaseProg compilers recognize C<term> to customize variable to get data
from).

=item * allow_expr => BOOL (default: 1)

Whether to allow expressions. If false, will die when encountering expression
during compilation. Usually set to false for security reason, to disallow
complex expressions when schemas come from untrusted sources.

=back

=head3 Compilation data

During compilation, compile() will call various hooks (listed below). The hooks
will be passed compilation data (C<$cd>) which is a hashref containing various
compilation state and result. Compilation data is written to this hashref
instead of on the object's attributes to make it easy to do recursive
compilation (compilation of subschemas).

Subclasses may add more data (see their documentation).

Keys which contain input data, compilation state, and others (many of these keys
might exist only temporarily during certain phases of compilation and will no
longer exist at the end of compilation, for example C<cset> will only exist
during processing of a clause set and will be seen by hooks like
C<before_clause_set>, C<before_clause>, C<after_clause>, and
C<after_clause_set>, it will not be seen by C<after_input>):

=over 4

=item * B<args> => HASH

Arguments given to C<compile()>.

=item * B<compiler> => OBJ

The compiler object.

=item * B<th_map> => HASH

Mapping of fully-qualified type names like C<int> and its
C<Data::Sah::Compiler::*::TH::*> type handler object (or array, a normalized
schema).

=item * B<fsh_map> => HASH

<apping of function set name like C<core> and its
C<Data::Sah::Compiler::*::FSH::*> handler object.

=item * B<input> => HASH

The current input (taken from C<< $cd->{args}{inputs} >>).

=item * B<schema> => ARRAY

The current schema (normalized) being processed.

=item C<th> => OBJ

Current type handler.

=item C<type> => STR

Current type name.

=item C<cset> => HASH

Current clause set being processed.

=item C<ucset> => HASH

Short for "unprocessed clause set", a shallow copy of C<cset>, keys will be
removed from here as they are processed by clause handlers, remaining keys after
processing the clause set means they are not recognized by hooks and thus
constitutes an error.

=item B<lang> => STR

Current language in the current clause set.

=item * B<prefilters> => ARRAY ?

Names of current prefilters in the current clause set.

=item * B<postfilters> => ARRAY ?

Names of current postfilters in the current clause set.

=item * C<clause> => STR

Current clause name.

=item * C<cl_meta> => HASH

Metadata information about the clause, from the clause definition. This include
C<prio> (priority), C<attrs> (list of attributes specific for this clause),
C<allow_expr> (whether clause allows expression in its value), etc. See
C<Data::Sah::Type::$TYPENAME> for more information.

=item * C<cl_term> => STR

Clause value term. If clause value is a literal (C<.is_expr> is false) then it
is produced by passing clause value to C<literal()>. Otherwise, it is produced
by passing clause value to C<expr()>.

=item * C<cl_is_expr> => STR

A shortcut for C<< $cd->{cset}{"${clause}.is_expr"} >>.

=item * C<cl_is_multi> => STR

A shortcut for C<< $cd->{cset}{"${clause}.is_multi"} >>.

=item * C<indent_level> => INT

Current level of indent when printing result using C<< $c->line() >>. 0 means
unindented.

=back

Keys which contain compilation result:

=over 4

=item * B<result>

Array of lines.

=back

=head3 Return value

The compilation data will be returned as return value. Main result will be in
the C<result> key, although subclasses may put additional results in other keys.

=head3 Hooks

By default this base compiler does not define any hooks; subclasses can define
hooks to implement their compilation process. Each hook will be passed
compilation data, and should modify or set the compilation data as needed. The
hooks that compile() will call at various points, in calling order, are:

=over 4

=item * $c->before_compile($cd)

Called once at the beginning of compilation.

If hook sets $cd->{SKIP_ALL_INPUTS} to true then the whole compilation
process will end (after_compile() will not even be called).

=item * $c->before_input($cd)

Called at the start of processing each input.

If hook sets $cd->{SKIP_THIS_INPUT} to true then compilation for the current
input ends and compilation moves on to the next input. This can be used, for
example, to skip recompiling a schema that has been compiled before.

=item * $c->before_all_clauses($cd)

Called before calling handler for any clauses.

=item * $th->before_all_clauses($cd)

Called before calling handler for any clauses, after compiler's
before_all_clauses().

=item * $th->before_clause_set($cd)

Flag: SKIP_THIS_CLAUSE_SET, SKIP_REMAINING_CLAUSES

=item * $c->before_clause_set($cd)

Flag: SKIP_THIS_CLAUSE_SET, SKIP_REMAINING_CLAUSES

=item * $c->before_clause($cd)

Called for each clause, before calling the actual clause handler
($th->clause_NAME() or $th->clause).

If hook sets $cd->{SKIP_THIS_CLAUSE} to true then compilation for the clause
will be skipped (including calling clause_NAME() and after_clause()). If
$cd->{SKIP_REMAINING_CLAUSES} is set to true then compilation for the rest of
the schema's clauses will be skipped (including current clause's clause_NAME()
and after_clause()).

=item * $th->before_clause($cd)

After compiler's before_clause() is called, I<type handler>'s before_clause()
will also be called if available.

Input and output interpretation is the same as compiler's before_clause().

=item * $th->clause_NAME($cd)

Called once for each clause. If hook sets $cd->{SKIP_REMAINING_CLAUSES} to true
then compilation for the rest of the clauses to be skipped (including current
clause's after_clause()).

=item * $th->after_clause($cd)

Called for each clause, after calling the actual clause handler
($th->clause_NAME()).

If hook sets $cd->{SKIP_REMAINING_CLAUSES} to true then compilation for the rest
of the clauses to be skipped.

=item * $c->after_clause($cd)

Called for each clause, after calling the actual clause handler
($th->clause_NAME()).

Output interpretation is the same as $th->after_clause().

=item * $th->after_clause_set($cd)

Flag: SKIP_REMAINING_CLAUSES

=item * $c->after_clause_set($cd)

Flag: SKIP_REMAINING_CLAUSES

=item * $th->after_all_clauses($cd)

Called after all clauses have been compiled, before compiler's
after_all_clauses().

=item * $c->after_all_clauses($cd)

Called after all clauses have been compiled.

=item * $c->after_input($cd)

Called for each input after compiling finishes.

If hook sets $cd->{SKIP_REMAINING_INPUTS} to true then remaining inputs will be
skipped.

=item * $c->after_compile($cd)

Called at the very end before compiling process end.

=back

=head2 $c->line($cd, @arg)

Append a line to C<< $cd->{result} >>. Will use C<< $cd->{indent_level} >> to
indent the line. Used by compiler; users normally do not need this. Example:

 $c->line($cd, 'this is a line', ' of ', 'code');

When C<< $cd->{indent_level} >> is 2 and C<< $cd->{args}{indent_width} >> is 2,
this line will be added with 4-spaces indent:

 this is a line of code

=head2 $c->inc_indent($cd)

Increase indent level. This is done by increasing C<< $cd->{indent_level} >> by
1.

=head2 $c->dec_indent($cd)

Decrease indent level. This is done by decreasing C<< $cd->{indent_level} >> by
1.

=head2 $c->get_th

=head2 $c->get_fsh

=cut
