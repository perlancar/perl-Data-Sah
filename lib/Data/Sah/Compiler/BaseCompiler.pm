package Data::Sah::Compiler::BaseCompiler;

use 5.010;
#use Carp;
use Moo;
use Log::Any qw($log);
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

# clause value term (either literal or expression)
sub _vterm {
    my ($self, $crec) = @_;
    defined($crec->{"val="}) ?
        $self->_expr($crec->{"val="}) : $self->_dump($crec->{val});
}

sub _v_is_expr {
    my ($self, $crec) = @_;
    defined($crec->{"val="}) ? 1 : 0;
}

# clause attribut term (either literal or expression)
sub _aterm {
    my ($self, $crec, $name) = @_;
    defined($crec->{attrs}{"$name="}) ?
        $self->_expr($crec->{attrs}{"$name="}) :
            $self->_dump($crec->{attrs}{$name});
}

sub _a_is_expr {
    my ($self, $crec, $name) = @_;
    defined($crec->{attrs}{"$name="}) ? 1: 0;
}

sub _die {
    my ($self, $msg) = @_;
    die "Sah ". $self->name . " compiler: $msg";
}

# form dependency list from which clauses are mentioned in expressions
# NEED TO BE UPDATED: NEED TO CHECK EXPR IN ALL ATTRS
sub _form_deps {
    require Algorithm::Dependency::Ordered;
    require Algorithm::Dependency::Source::HoA;
    require Language::Expr::Interpreter::VarEnumer;

    my ($self, $ctbl) = @_;
    my $main = $self->main;
    $main->_var_enumer(Language::Expr::Interpreter::VarEnumer->new)
        unless $main->_var_enumer;

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

# parse a schema's clause sets (csets, arrayref) into clauses table (ctbl,
# hashref). csets should already be normalized and merged (preferably result
# from _resolve_base_type).
sub _parse_csets_to_ctbl {
    my ($self, $csets, $type, $th) = @_;
    my %ctbl; # key = name#index

    for my $i (0..@$csets-1) {
        my $cset = $csets->[$i];
        for my $cn0 (keys %$cset) {
            my $cv = $cset->{$cn0};
            my ($name, $attr, $expr) = $cn0 =~
                /\A(\w+(?:::\w+)*)?(?:\.(\w+(?:\.\w+)*))?(=?)\z/
                    or $self->_die("Invalid clause name syntax: $cn0, ".
                                       "please use NAME(.ATTR)=? or .ATTR=?");
            $name //= "";
            $attr //= "";
            $expr //= "";

            $self->_die("Clause '$name' not implemented by type handler ".
                            ref($th))
                if length($name) && !$th->can("clause_$name");

            my $key = "$name#$i";
            my $crec;
            if (!$ctbl{$key}) {
                $crec = {cset_idx=>$i, cset=>$cset, name=>$name};
                $ctbl{$key} = $crec;
            } else {
                $crec = $ctbl{$key};
            }
            if (length($attr)) {
                $crec->{attrs} //= {};
                $crec->{attrs}{"$attr$expr"} = $cv;
            } else {
                $crec->{"val$expr"} = $cv;
            }
        }
    }

    $ctbl{SANITY} = {cset_idx=>-1, name=>"SANITY", cset=>undef};

    $self->_sort_ctbl(\%ctbl, $type);
    #use Data::Dump; dd \%ctbl;

    \%ctbl;
}

# check a normalized schema for an expression in one of its clauses. this can be
# used to skip calculating expression dependencies when none of schema's clauses
# has expressions.
sub _nschema_has_expr {
    my ($self, $ns) = @_;
    return 1 if defined $ns->[1]{check};
    for (keys %{$ns->[1]}) {
        return 1 if /=$/;
    }
    0;
}

# like _nschema_has_expr(), but check a clauses table instead.
sub _ctbl_has_expr {
    my ($self, $ctbl) = @_;
    for my $crec (values %$ctbl) {
        return 1 if defined($crec->{"value="});
        next unless $crec->{attrs};
        for (keys %{$crec->{attrs}}) {
            return 1 if /=$/;
        }
    }
    0;
}

# sort clauses table in-place, based on priority and expression dependencies.
# also sets each clause record's 'order' key as side effect.
sub _sort_ctbl {
    my ($self, $ctbl, $type) = @_;

    my $deps;
    if ($self->_ctbl_has_expr($ctbl)) {
        $deps = $self->_form_deps($ctbl);
    } else {
        $deps = {};
    }

    my $sorter = sub {
        my $na = $a->{name};
        my $pa;
        if (length($na)) {
            $pa = "clauseprio_$na"; $pa = "Data::Sah::Type::$type"->$pa;
        } else {
            $pa = 0;
        }
        my $nb = $b->{name};
        my $pb;
        if (length($nb)) {
            $pb = "clauseprio_$nb"; $pb = "Data::Sah::Type::$type"->$pb;
        } else {
            $pb = 0;
        }
        ($deps->{$na} // -1) <=> ($deps->{$nb} // -1) ||
        $pa <=> $pb ||
        $a->{cset_idx} <=> $b->{cset_idx} ||
        $a->{name} cmp $b->{name}
    };

    # give order value, according to sorting order
    my $order = 0;
    for (sort $sorter values %$ctbl) {
        $_->{order} = $order++;
    }
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
    my $inputs = $args{inputs} or $self->_die("Please specify inputs");
    ref($inputs) eq 'ARRAY' or $self->_die("inputs must be an array");

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

        $log->tracef("Parsing clause sets into clause table ...");
        my $ctbl = $self->_parse_csets_to_ctbl($csets, $tn, $th);
        local $cd->{ctbl} = $ctbl;

        if ($th->can("before_all_clauses")) {
            $log->tracef("=> before_all_clauses()");
            $th->before_all_clauses($cd);
            goto FINISH_INPUT if delete $cd->{SKIP_ALL_CLAUSES};
        }

      CLAUSE:
        for my $c (sort {$a->{order} <=> $b->{order}} values %$ctbl) {
            $log->tracef("Processing %s clause: %s", $tn, $c);
            local $cd->{clause} = $c;

            # empty clause only contains attributes
            next unless exists($c->{val}) || defined($c->{"val="});

            if ($self->can("before_clause")) {
                $log->tracef("=> compiler's before_clause()");
                $self->before_clause($cd);
                next CLAUSE if delete $cd->{SKIP_THIS_CLAUSE};
                goto FINISH_INPUT if delete $cd->{SKIP_REMAINING_CLAUSES};
            }

            if ($th->can("before_clause")) {
                $log->tracef("=> type handler's before_clause()");
                $th->before_clause($cd);
                next CLAUSE if delete $cd->{SKIP_THIS_CLAUSE};
                goto FINISH_INPUT if delete $cd->{SKIP_REMAINING_CLAUSES};
            }

            my $meth = "clause_$c->{name}";
            $log->tracef("=> type handler's $meth()");
            $th->$meth($cd);
            goto FINISH_INPUT if $cd->{SKIP_REMAINING_CLAUSES};

            if ($th->can("after_clause")) {
                $log->tracef("=> type handler's after_clause()");
                $th->after_clause($cd);
                goto FINISH_INPUT if $cd->{SKIP_REMAINING_CLAUSES};
            }

            if ($self->can("after_clause")) {
                $log->tracef("=> compiler's after_clause()");
                $self->after_clause($cd);
                goto FINISH_INPUT if $cd->{SKIP_REMAINING_CLAUSES};
            }
        } # for each clause

        if ($th->can("after_all_clauses")) {
            $log->tracef("=> after_all_clauses()");
            $th->after_all_clauses($cd);
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
    $cd;
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

=item * inputs => ARRAYREF

A list of inputs. Each input is a hashref with the following keys: B<schema>,
B<normalized> (bool, set to true if input schema is already normalized to skip
normalization step). Subclasses may require/recognize additional keys (for
example, ProgBase compilers recognize C<data_term> to customize variable to get
data from).

=back

About B<compilation data> (B<$cd>): During compilation, compile() will call
various hooks (listed below). The hooks will be passed compilation data ($cd)
which is a hashref containing various compilation state and result. Compilation
state is written to this hashref instead of on the object's attributes to make
it easy to do recursive compilation (compilation of subschemas).

These keys (subclasses may add more data): B<args> (arguments given to
compile()), B<compiler> (the compiler object), B<result>, B<input> (current
input), B<schema> (current schema we're compiling), B<ctbl> (clauses table, see
explanation below), B<lang> (current language), C<clause> (current clause),
C<th> (current type handler), C<cres> (result of clause handler), B<prefilters>
(an array of containing names of current prefilters), B<postfilters> (an array
containing names of postfilters), B<th_map> (a hashref containing mapping of
fully-qualified type names like C<int> and its Data::Sah::Compiler::*::TH::*
type handler object (or array, normalized schema), B<fsh_map> (a hashref
containing mapping of function set name like C<core> and its
Data::Sah::Compiler::*::FSH::* handler object).

About B<clauses table> (B<ctbl>): A single hashref containing all the clauses to
be processed, parsed from schema's (normalized and merged) clause sets. Clause
table is easier to use by the handlers. Each hash key is clause name, stripped
from all attributes, in the form of NAME (e.g. 'min') or NAME#INDEX if there are
more than one clause of the same name (e.g. 'min#1', 'min#2' and so on).

Each hash value is called a B<clause record> (B<crec>) which is a hashref:
{name=>..., value=>...., 'value='=>..., attrs=>{...}, order=>..., cset_idx=>...,
cset=>...]. 'name' is the clause name (no attributes, or #INDEX suffixes),
'value' is the clause value ('value=' is set instead if clause value is an
expression), 'attrs' is a hashref containing attribute names and values
(attribute names can contain '=' suffix if its value is an expression), 'order'
is the processing order (1, 2, 3, ...), 'cset_idx' is the index to the original
clause sets arrayref, 'cset' is reference to the original clause set.

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
