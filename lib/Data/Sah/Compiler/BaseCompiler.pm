package Data::Sah::Compiler::BaseCompiler;

use 5.010;
#use Carp;
use Moo;
use Log::Any qw($log);

use Hash::DefHash;
use Scalar::Util qw(blessed);

# VERSION

has main => (is => 'rw');

# instance to Language::Expr::Compiler::* instance
has expr_compiler => (is => 'rw');

sub name {
    die "Please override name()";
}

# dump value literal in target language
sub _dump {
    die "Please override _dump()";
}

# compile expression to target language
sub _expr {
    die "Please override _expr()";
}

sub _die {
    my ($self, $msg) = @_;
    die "Sah ". $self->name . " compiler: $msg";
}

# form dependency list from which clauses are mentioned in expressions NEED TO
# BE UPDATED: NEED TO CHECK EXPR IN ALL ATTRS, ctbl NO LONGER A HASH.
sub _form_deps {
    require Algorithm::Dependency::Ordered;
    require Algorithm::Dependency::Source::HoA;
    require Language::Expr::Interpreter::VarEnumer;

    my ($self, $ctbl) = @_;
    my $main = $self->main;

    my %depends;
    for my $crec (values %$ctbl) {
        my $cn = $crec->{name};
        my $expr = defined($crec->{expr}) ? $crec->{value} :
            $crec->{attrs}{expr};
        if (defined $expr) {
            my $vars = $main->_var_enumer->eval($expr);
            for (@$vars) {
                /^\w+$/ or $self->_die(
                    "Invalid variable syntax `$_`, ".
                        "currently only the form \$abc is supported");
                $ctbl->{$_} or $self->_die(
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
    my $th   = $self->_get_th(name=>$t, cd=>$cd);
    my $seen = $args{seen} // {};
    my $res  = $args{res} // [$t, [], []];

    $self->_die("Recursive dependency on type '$t'") if $seen->{$t}++;

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
# arrayref (clauses table, ctbl). see POD for more details on ctbl.
sub _sort_cset {
    my ($self, $cset, $tn, $th) = @_;

    my $deps;
    ## temporarily disabled, expr needs to be sorted globally
    #if ($self->_cset_has_expr($cset)) {
    #    $deps = $self->_form_deps($ctbl);
    #} else {
    #    $deps = {};
    #}
    $deps = {};

    my $dh = defhash($cset);
    my @ctbl = map { +{
        name  => $_,
        value => $dh->prop($_),
        attrs => {$dh->attrs($_)},
        cset  => $cset,
    } } $dh->props;

    my $sorter = sub {
        my $na = $a->{name};
        my $pa;
        if (length($na)) {
            $pa = "clauseprio_$na"; $pa = "Data::Sah::Type::$tn"->$pa;
        } else {
            $pa = 0;
        }
        my $nb = $b->{name};
        my $pb;
        if (length($nb)) {
            $pb = "clauseprio_$nb"; $pb = "Data::Sah::Type::$tn"->$pb;
        } else {
            $pb = 0;
        }

        ($deps->{$na} // -1) <=> ($deps->{$nb} // -1) ||
            $pa <=> $pb ||
                ($a->{attrs}{prio} // 50) <=> ($b->{attrs}{prio} // 50) ||
                    $a->{name} cmp $b->{name};
    };

    @ctbl = sort $sorter @ctbl;

    # give order value, according to sorting order
    my $order = 0;
    for (@ctbl) {
        $_->{order} = $order++;
    }

    \@ctbl;
}

sub _get_th {
    my ($self, %args) = @_;
    my $cd    = $args{cd};
    my $name  = $args{name};

    my $th_map = $cd->{th_map};
    return $th_map->{$name} if $th_map->{$name};

    if ($args{load} // 1) {
        no warnings;
        $self->_die("Invalid syntax for type name '$name', please use ".
                        "letters/numbers/underscores only")
            unless $name =~ $Data::Sah::type_re;
        my $main = $self->main;
        my $module = ref($self) . "::TH::$name";
        if (!eval "require $module; 1") {
            $self->_die("Can't load type handler $module".
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
        $self->_die("Invalid syntax for func set name `$name`, please use ".
                        "letters/numbers/underscores")
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

sub _init_cd {
    my ($self, %args) = @_;

    my $outer_cd = $args{outer_cd};
    my $cd = $outer_cd ? { %$outer_cd, outer_cd=>$outer_cd } : {};
    $cd->{args}         = \%args;
    $cd->{th_map}     //= {};
    $cd->{fsh_map}    //= {};
    $cd->{result}     //= {};
    $cd->{default_lang} = $cd->{lang} // $ENV{LANG} // "en_US";
    $cd->{default_lang} =~ s/\..+//; # en_US.UTF-8 -> en_US

    $cd;
}

sub compile {
    my ($self, %args) = @_;
    $log->tracef("-> compile(%s)", \%args);

    # XXX schema
    my %seen;
    my $inputs = $args{inputs} or $self->_die("Please specify inputs");
    ref($inputs) eq 'ARRAY' or $self->_die("inputs must be an array");
    for my $i (0..@$inputs-1) {
        ref($inputs->[$i]) eq 'HASH' or $self->_die("inputs[$i] must be hash");
        defined($inputs->[$i]{name}) or $self->_die(
            "Please specify inputs[$i]{name}");
        $inputs->[$i]{name} =~ /\A[A-Za-z_]\w*\z/ or $self->_die(
            "Invalid syntax in inputs[$i]{name}, please use letters/nums only");
        $seen{ $inputs->[$i]{name} } and $self->_die(
            "Duplicate name in inputs[$i]{name} '$inputs->[$i]{name}'");
    }

    my $main = $self->main;

    my $cd = $self->_init_cd(%args);

    if ($self->can("before_compile")) {
        $log->tracef("=> before_compile()");
        $self->before_compile($cd);
        goto SKIP_ALL_INPUTS if delete($cd->{SKIP_ALL_INPUTS});
    }

    my $i = 0;
  INPUT:
    for my $input (@$inputs) {

        my $th_map_before_def;

        $log->tracef("input=%s", $input);
        local $cd->{input} = $input;

        if ($self->can("before_input")) {
            $log->tracef("=> before_input()");
            $self->before_input($cd);
            next INPUT if delete $cd->{SKIP_THIS_INPUT};
            goto SKIP_REMAINING_INPUTS if delete $cd->{SKIP_REMAINING_INPUTS};
        }

        my $schema0 = $input->{schema} or $self->_die("Input #$i: No schema");

        my $nschema;
        if ($input->{normalized}) {
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
                    $self->_die("Invalid name syntax in def: '$name'")
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
        my $th     = $self->_get_th(name=>$tn, cd=>$cd);
        my $csets  = $res->[1];
        local $cd->{th} = $th;

        if ($self->can("before_all_clauses")) {
            $log->tracef("=> c->before_all_clauses()");
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
            local $cd->{cset} = $cset;

            my $ctbl = $self->_sort_cset($cset, $tn, $th);
            local $cd->{ctbl} = $ctbl;

            if ($self->can("before_clause_set")) {
                $log->tracef("=> c->before_clause_set()");
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
            for my $c (sort {$a->{order} <=> $b->{order}} @$ctbl) {
                $log->tracef("Processing %s clause: %s", $tn, $c);
                local $cd->{crec} = $c;

                if ($self->can("before_clause")) {
                    $log->tracef("=> c->before_clause()");
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

                my $meth = "clause_$c->{name}";
                $log->tracef("=> type handler's $meth()");
                $th->$meth($cd);
                goto FINISH_INPUT if $cd->{SKIP_REMAINING_CLAUSES};

                if ($th->can("after_clause")) {
                    $log->tracef("=> th->after_clause()");
                    $th->after_clause($cd);
                    goto FINISH_INPUT if $cd->{SKIP_REMAINING_CLAUSES};
                }
                if ($self->can("after_clause")) {
                    $log->tracef("=> c->after_clause()");
                    $self->after_clause($cd);
                    goto FINISH_INPUT if $cd->{SKIP_REMAINING_CLAUSES};
                }
            } # for clause

                if ($th->can("after_clause_set")) {
                    $log->tracef("=> th->after_clause()");
                    $th->after_clause($cd);
                    goto FINISH_INPUT if $cd->{SKIP_REMAINING_CLAUSES};
                }
                if ($self->can("after_clause_set")) {
                    $log->tracef("=> c->after_clause()");
                    $self->after_clause($cd);
                    goto FINISH_INPUT if $cd->{SKIP_REMAINING_CLAUSES};
                }

        } # for cset

        if ($th->can("after_all_clauses")) {
            $log->tracef("=> th->after_all_clauses()");
            $th->after_all_clauses($cd);
        }
        if ($self->can("after_all_clauses")) {
            $log->tracef("=> c->after_all_clauses()");
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

sub def {
    my ($self, $cd) = @_;
    my $name = $cd->{def_name};
    my $def  = $cd->{def_def};
    my $opt  = $cd->{def_optional};

    my $th = $self->_get_th(cd=>$cd, name=>$name, load=>0);
    if ($th) {
        if ($opt) {
            $log->tracef("Not redefining already-defined schema/type '$name'");
            return;
        }
        $self->_die("Redefining existing type ($name) not allowed");
    }

    my $nschema = $self->main->normalize_schema($def);
    $cd->{th_map}{$name} = $nschema;
}

1;
# ABSTRACT: Base class for Sah compilers (Data::Sah::Compiler::*)

=head1 ATTRIBUTES

=head2 main => OBJ

Reference to the main Data::Sah object.


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

=back

About B<compilation data> (B<$cd>): During compilation, compile() will call
various hooks (listed below). The hooks will be passed compilation data ($cd)
which is a hashref containing various compilation state and result. Compilation
state is written to this hashref instead of on the object's attributes to make
it easy to do recursive compilation (compilation of subschemas).

These keys (subclasses may add more data): B<args> (arguments given to
compile()), B<compiler> (the compiler object), B<result>, B<input> (current
input), B<schema> (current schema we're compiling), B<ctbl> (clauses table, see
explanation below), B<lang> (current language), C<crec> (current clause record),
C<cset> (current clause set), C<th> (current type handler), C<cres> (result of
clause handler), B<prefilters> (an array of containing names of current
prefilters), B<postfilters> (an array containing names of postfilters),
B<th_map> (a hashref containing mapping of fully-qualified type names like
C<int> and its Data::Sah::Compiler::*::TH::* type handler object (or array,
normalized schema), B<fsh_map> (a hashref containing mapping of function set
name like C<core> and its Data::Sah::Compiler::*::FSH::* handler object).

About B<clauses table> (B<ctbl>): An array, containing sorted clause set
entries. Each element of this array is called a B<clause record> (B<crec>) which
is a hashref: C<< {name=>..., value=>...., attrs=>{...}, order=>..., cset=>...}
>>. C<name> is the clause name (no attributes, or #INDEX suffixes), C<value> is
the clause value, C<attrs> is a hashref containing attribute names and values,
C<order> is the processing order (0, 1, 2, 3, ...), C<cset> is reference to the
original clause set.

B<Return value>. Compilation data will be returned. Compilation data should have
these keys: B<result> (the final compilation result, usually a string like Perl
code or human text). There could be other metadata which are compiler-specific
(see respective compiler for more information).

B<Hooks>. By default this base compiler does not define any hooks; subclasses
can define hooks to implement their compilation process. Each hook will be
passed compilation data, and should modify or set the compilation data as
needed. The hooks that compile() will call at various points, in calling order,
are:

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

After compiler's before_clause() is called, type handler's before_clause() will
also be called if available (note that this method is called on the compiler's
type handler class, not the compiler class itself.)

Input and output interpretation is the same as compiler's before_clause().

=item * $th->clause_NAME($cd)

Note that this method is called on the compiler's type handler class, not the
compiler class itself. NAME is the name of the clause.

If hook sets $cd->{SKIP_REMAINING_CLAUSES} to true then compilation for the rest
of the clauses to be skipped (including current clause's after_clause()).

=item * $th->after_clause($cd)

Note that this method is called on the compiler's type handler class, not the
compiler class itself. Called for each clause, after calling the actual clause
handler ($th->clause_NAME()).

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

=cut
