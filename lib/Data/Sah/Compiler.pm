package Data::Sah::Compiler;

use 5.010;
#use Carp;
use Moo;
use Log::Any qw($log);

with 'Data::Sah::Compiler::TextResultRole';

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

sub name {
    die "BUG: Please override name()";
}

# literal representation in target language
sub literal {
    die "BUG: Please override literal()";
}

# compile expression to target language
sub expr {
    die "BUG: Please override expr()";
}

sub _die {
    my ($self, $cd, $msg) = @_;
    die join(
        "",
        "Sah ". $self->name . " compiler: ",
        # XXX show (snippet of) current schema
        $msg,
    );
}

# form dependency list from which clauses are mentioned in expressions NEED TO
# BE UPDATED: NEED TO CHECK EXPR IN ALL ATTRS FOR THE WHOLE SCHEMA/SUBSCHEMAS
# (NOT IN THE CURRENT CSET ONLY), THERE IS NO LONGER A ctbl, THE WAY EXPR IS
# STORED IS NOW DIFFERENT. PLAN: NORMALIZE ALL SUBSCHEMAS, GATHER ALL EXPR VARS
# AND STORE IN $cd->{all_expr_vars} (SKIP DOING THIS IS
# $cd->{outer_cd}{all_expr_vars} is already defined).
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
                    "Unhandled clause specified in variable '$_'");
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

# clauses in csets in order of evaluation. clauses are sorted based on
# expression dependencies and priority. result is array of [CSET_NUM, CLAUSE]
# pairs, e.g. ([0, 'default'], [1, 'default'], [0, 'min'], [0, 'max']).
sub _sort_csets {
    my ($self, $cd, $csets) = @_;
    my $tn = $cd->{type};
    my $th = $cd->{th};

    my $deps;
    ## temporarily disabled, expr needs to be sorted globally
    #if ($self->_cset_has_expr($cset)) {
    #    $deps = $self->_form_deps($ctbl);
    #} else {
    #    $deps = {};
    #}
    #$deps = {};

    my $sorter = sub {
        my ($ia, $ca) = @$a;
        my ($ib, $cb) = @$b;
        my $res;

        # dependency
        #$res = ($deps->{"$ca.$ia"} // -1) <=> ($deps->{"$cb.$ib"} // -1);
        #return $res if $res;

        # prio from clause definition
        my ($metaa, $metab);
        eval {
            $metaa = "Data::Sah::Type::$tn"->${\("clausemeta_$ca")};
        };
        if ($@) {
            given ($cd->{args}{on_unhandled_clause}) {
                my $msg = "Unhandled clause for type $tn: $ca";
                0 when 'ignore';
                warn $msg when 'warn';
                $self->_die($cd, $msg);
            }
        }
        $metaa //= {prio=>50};
        eval {
            $metab = "Data::Sah::Type::$tn"->${\("clausemeta_$cb")};
        };
        if ($@) {
            given ($cd->{args}{on_unhandled_clause}) {
                my $msg = "Unhandled clause for type $tn: $cb";
                0 when 'ignore';
                warn $msg when 'warn';
                $self->_die($cd, $msg);
            }
        }
        $metab //= {prio=>50};
        $res = $metaa->{prio} <=> $metab->{prio};
        return $res if $res;

        # prio from schema
        my $sprioa = $csets->[$ia]{"$ca.prio"} // 50;
        my $spriob = $csets->[$ib]{"$cb.prio"} // 50;
        $res = $sprioa <=> $spriob;
        return $res if $res;

        # alphabetical order of clause name
        $res = $a cmp $b;
        return $res if $res;

        # clause set order
        $res = $ia <=> $ib;
        return $res if $res;

        0;
    };

    my @clauses;
    for my $i (0..@$csets-1) {
        push @clauses, map {[$i, $_]}
            grep {!/\A_/ && !/\./} keys %{$csets->[$i]};
    }

    [sort $sorter @clauses];
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

    my $cd = {};
    $cd->{args} = \%args;

    if (my $ocd = $args{outer_cd}) {
        $cd->{outer_cd}     = $ocd;
        $cd->{indent_level} = $ocd->{indent_level};
        $cd->{th_map}       = { %{ $ocd->{th_map}  } };
        $cd->{fsh_map}      = { %{ $ocd->{fsh_map} } };
        $cd->{default_lang} = $ocd->{default_lang};
    } else {
        $cd->{indent_level} = $cd->{args}{indent_level} // 0;
        $cd->{th_map}       = {};
        $cd->{fsh_map}      = {};
        $cd->{default_lang} = $ENV{LANG} // "en_US";
        $cd->{default_lang} =~ s/\..+//; # en_US.UTF-8 -> en_US
    }
    $cd->{ccls} = [];

    $cd;
}

sub check_compile_args {
    my ($self, $args) = @_;

    $args->{data_name} //= 'data';
    $args->{data_name} =~ /\A[A-Za-z_]\w*\z/ or $self->_die(
        {}, "Invalid syntax in data_name '$args->{data_name}', ".
            "please use letters/nums only");
    $args->{allow_expr} //= 1;
    $args->{on_unhandled_attr}   //= 'die';
    $args->{on_unhandled_clause} //= 'die';
    $args->{skip_clause}         //= [];
    $args->{mark_fallback}       //= 1;
    for ($args->{lang}) {
        $_ //= $ENV{LANG} // $ENV{LANGUAGE} // "en_US";
        s/\W.*//; # LANG=en_US.UTF-8, LANGUAGE=en_US:en
    }
    # locale, no default
}

sub compile {
    my ($self, %args) = @_;
    $log->tracef("-> compile(%s)", \%args);

    # XXX schema
    $self->check_compile_args(\%args);
    $log->tracef("-> compile(%s)", \%args);

    my $main   = $self->main;
    my $cd     = $self->init_cd(%args);

    if ($self->can("before_compile")) {
        $log->tracef("=> before_compile()");
        $self->before_compile($cd);
        goto SKIP_COMPILE if delete $cd->{SKIP_COMPILE};
    }

    # normalize schema
    my $schema0 = $args{schema} or $self->_die($cd, "No schema");
    my $nschema;
    if ($args{schema_is_normalized}) {
        $nschema = $schema0;
        $log->tracef("schema already normalized, skipped normalization");
    } else {
        $nschema = $main->normalize_schema($schema0);
        $log->tracef("normalized schema=%s", $nschema);
    }
    $nschema->[2] //= {};
    local $cd->{schema} = $nschema;

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

    my $res      = $self->_resolve_base_type(schema=>$nschema, cd=>$cd);
    my $tn       = $res->[0];
    my $th       = $self->get_th(name=>$tn, cd=>$cd);
    my $csets    = $res->[1];
    $cd->{th}    = $th;
    $cd->{type}  = $tn;
    $cd->{csets} = $csets;

    my $cname = $self->name;
    $cd->{ucsets} = [];
    $cd->{_cset_dlangs} = []; # default lang for each cset
    for my $cset (@$csets) {
        for (keys %$cset) {
            if (!$args{allow_expr} && /\.is_expr\z/ && $cset->{$_}) {
                $self->_die($cd, "Expression not allowed: $_");
            }
        }
        push @{ $cd->{ucsets} }, {
            map {$_=>$cset->{$_}}
                grep {
                    !/\A_|\._/ && (!/\Ac\./ || /\Ac\.\Q$cname\E\./)
                } keys %$cset
        };
        my $dl = $cset->{default_lang} // $cd->{outer_cd}{cset_dlang} //
            "en_US";
        push @{ $cd->{_cset_dlangs} }, $dl;
    }

    my $clauses = $self->_sort_csets($cd, $csets);

    if ($self->can("before_handle_type")) {
        $log->tracef("=> comp->before_handle_type()");
        $self->before_handle_type($cd);
    }

    $log->tracef("=> th->handle_type()");
    $th->handle_type($cd);

    if ($self->can("before_all_clauses")) {
        $log->tracef("=> comp->before_all_clauses()");
        $self->before_all_clauses($cd);
        goto FINISH_COMPILE if delete $cd->{SKIP_ALL_CLAUSES};
    }
    if ($th->can("before_all_clauses")) {
        $log->tracef("=> th->before_all_clauses()");
        $th->before_all_clauses($cd);
        goto FINISH_COMPILE if delete $cd->{SKIP_ALL_CLAUSES};
    }

  CLAUSE:
    for my $clause0 (@$clauses) {
        my ($cset_num, $clause) = @$clause0;
        my $cset = $csets->[$cset_num];
        local $cd->{cset}       = $cset;
        local $cd->{cset_num}   = $cset_num;
        local $cd->{ucset}      = $cd->{ucsets}[$cset_num];
        local $cd->{cset_dlang} = $cd->{_cset_dlangs}[$cset_num];
        #$log->tracef("Processing clause %s: %s", $clause);

        delete $cd->{ucset}{$clause};
        delete $cd->{ucset}{"$clause.prio"};

        if ($clause ~~ $args{skip_clause}) {
            delete $cd->{ucset}{$_}
                for grep /^\Q$clause\E(\.|\z)/, keys(%{$cd->{ucset}});
            next CLAUSE;
        }

        my $meth  = "clause_$clause";
        my $mmeth = "clausemeta_$clause";
        unless ($th->can($meth)) {
            given ($args{on_unhandled_clause}) {
                0 when 'ignore';
                do { warn "Can't handle clause $clause"; next CLAUSE }
                    when 'warn';
                $self->_die($cd, "Compiler can't handle clause $clause");
            }
        }

        # put information about the clause to $cd

        my $meta;
        if ($th->can($mmeth)) {
            $meta = $th->$mmeth;
        } else {
            $meta = {};
        }
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
        my $ie = $cset->{"$clause.is_expr"};
        my $im = $cset->{"$clause.is_multi"};
        local $cd->{cl_value} = $cv unless $ie;
        local $cd->{cl_term} = $ie ? $self->expr($cv) : $self->literal($cv);
        local $cd->{cl_is_expr} = $ie;
        local $cd->{cl_is_multi} = $im;
        delete $cd->{ucset}{"$clause.is_expr"};
        delete $cd->{ucset}{"$clause.is_multi"};

        if ($self->can("before_clause")) {
            $log->tracef("=> comp->before_clause()");
            $self->before_clause($cd);
            next CLAUSE if delete $cd->{SKIP_THIS_CLAUSE};
            goto FINISH_COMPILE if delete $cd->{SKIP_REMAINING_CLAUSES};
        }
        if ($th->can("before_clause")) {
            $log->tracef("=> th->before_clause()");
            $th->before_clause($cd);
            next CLAUSE if delete $cd->{SKIP_THIS_CLAUSE};
            goto FINISH_COMPILE if delete $cd->{SKIP_REMAINING_CLAUSES};
        }

        $log->tracef("=> type handler's $meth()");
        $th->$meth($cd) if $th->can($meth);
        goto FINISH_COMPILE if $cd->{SKIP_REMAINING_CLAUSES};

        if ($th->can("after_clause")) {
            $log->tracef("=> th->after_clause()");
            $th->after_clause($cd);
            goto FINISH_COMPILE if $cd->{SKIP_REMAINING_CLAUSES};
        }
        if ($self->can("after_clause")) {
            $log->tracef("=> comp->after_clause()");
            $self->after_clause($cd);
            goto FINISH_COMPILE if $cd->{SKIP_REMAINING_CLAUSES};
        }
    } # for clause

    for my $ucset (@{ $cd->{ucsets} }) {
        if (keys %$ucset) {
            given ($args{on_unhandled_attr}) {
                my $msg = "Unhandled attribute(s) for type $tn: ".
                    join(", ", keys %$ucset);
                0 when 'ignore';
                warn $msg when 'warn';
                $self->_die($cd, $msg);
            }
        }
    }

    if ($th->can("after_all_clauses")) {
        $log->tracef("=> th->after_all_clauses()");
        $th->after_all_clauses($cd);
    }
    if ($self->can("after_all_clauses")) {
        $log->tracef("=> comp->after_all_clauses()");
        $self->after_all_clauses($cd);
    }

  FINISH_COMPILE:
    if ($self->can("after_compile")) {
        $log->tracef("=> after_compile()");
        $self->after_compile($cd);
    }

  SKIP_COMPILE:
    if ($Data::Sah::Log_Validator_Code && $log->is_trace) {
        require SHARYANTO::String::Util;
        $log->tracef("Schema compilation result:\n%s",
                     SHARYANTO::String::Util::linenum($cd->{result}));
    }
    $log->tracef("<- compile()");
    return $cd;
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

sub _ignore_clause {
    my ($self, $cd) = @_;
    my $cl = $cd->{clause};
    delete $cd->{ucset}{$cl};
}

sub _ignore_clause_and_attrs {
    my ($self, $cd) = @_;
    my $cl = $cd->{clause};
    delete $cd->{ucset}{$cl};
    delete $cd->{ucset}{$_} for grep /\A\Q$cl\E\./, keys %{$cd->{ucset}};
}

1;
# ABSTRACT: Base class for Sah compilers (Data::Sah::Compiler::*)

=for Pod::Coverage ^(check_compile_args|def|expr|init_cd|literal|name)$

=head1 ATTRIBUTES

=head2 main => OBJ

Reference to the main Data::Sah object.

=head2 expr_compiler => OBJ

Reference to expression compiler object. In the perl compiler, for example, this
will be an instance of L<Language::Expr::Compiler::Perl> object.


=head1 METHODS

=head2 new() => OBJ

=head2 $c->compile(%args) => HASH

Compile schema into target language.

Arguments (C<*> denotes required arguments, subclass may introduce others):

=over 4

=item * data_name => STR (default: 'data')

A unique name. Will be used as default for variable names, etc. Should only be
comprised of letters/numbers/underscores.

=item * schema* => STR|ARRAY

The schema to use. Will be normalized by compiler, unless
C<schema_is_normalized> is set to true.

=item * lang => STR (default: from LANG/LANGUAGE or C<en_US>)

Desired output human language. Defaults (and falls back to) C<en_US>.

=item * mark_fallback => BOOL (default: 1)

If a piece of text is not found in desired human language, C<en_US> version of
the text will be used but using this format:

 (en_US:the text to be translated)

If you do not want this marker, set the C<mark_fallback> option to 0.

=item * locale => STR

Locale name, to be set during generating human text description. This sometimes
needs to be if setlocale() fails to set locale using only C<lang>.

=item * schema_is_normalized => BOOL (default: 0)

If set to true, instruct the compiler not to normalize the input schema and
assume it is already normalized.

=item * allow_expr => BOOL (default: 1)

Whether to allow expressions. If false, will die when encountering expression
during compilation. Usually set to false for security reason, to disallow
complex expressions when schemas come from untrusted sources.

=item * on_unhandled_attr => STR (default: 'die')

What to do when an attribute can't be handled by compiler (either it is an
invalid attribute, or the compiler has not implemented it yet). Valid values
include: C<die>, C<warn>, C<ignore>.

=item * on_unhandled_clause => STR (default: 'die')

What to do when a clause can't be handled by compiler (either it is an invalid
clause, or the compiler has not implemented it yet). Valid values include:
C<die>, C<warn>, C<ignore>.

=item * indent_level => INT (default: 0)

Start at a specified indent level. Useful when generated code will be inserted
into another code (e.g. inside C<sub {}> where it is nice to be able to indent
the inside code).

=item * skip_clause => ARRAY (default: [])

List of clauses to skip (to assume as if it did not exist). Example when
compiling with the human compiler:

 # schema
 [int => {default=>1, between=>[1, 10]}]

 # generated human description in English
 integer, between 1 and 10, default 1

 # generated human description, with skip_clause => ['default']
 integer, between 1 and 10

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
longer exist at the end of compilation, for example C<clause> will only exist
during processing of a clause and will be seen by hooks like C<before_clause>
and C<after_clause>, it will not be seen by C<before_all_clauses> or
C<after_compile>):

=over 4

=item * B<args> => HASH

Arguments given to C<compile()>.

=item * B<compiler> => OBJ

The compiler object.

=item * B<outer_cd> => HASH

If compilation is called from within another C<compile()>, this will be set to
the outer compilation's C<$cd>. The inner compilation will inherit some values
from the outer, like list of types (C<th_map>) and function sets (C<fsh_map>).

=item * B<th_map> => HASH

Mapping of fully-qualified type names like C<int> and its
C<Data::Sah::Compiler::*::TH::*> type handler object (or array, a normalized
schema).

=item * B<fsh_map> => HASH

Mapping of function set name like C<core> and its
C<Data::Sah::Compiler::*::FSH::*> handler object.

=item * B<schema> => ARRAY

The current schema (normalized) being processed. Since schema can contain other
schemas, there will be subcompilation and this value will not necessarily equal
to C<< $cd->{args}{schema} >>.

=item * B<th> => OBJ

Current type handler.

=item * B<type> => STR

Current type name.

=item * B<csets> => ARRAY

All the clause sets. Each schema might have more than one clause set, due to
processing base type's clause set.

=item * B<cset> => HASH

Current clause set being processed. Note that clauses are evaluated not strictly
in cset order, but instead based on expression dependencies and priority.

=item * B<cset_dlang> => HASH

Default language of the current clause set. This value is taken from C<<
$cd->{cset}{default_lang} >> or C<< $cd->{outer_cd}{default_lang} >> or the
default C<en_US>.

=item * B<cset_num> => INT

Set to 0 for the first clause set, 1 for the second, and so on. Due to merging,
we might process more than one clause set during compilation.

=item * B<ucset> => HASH

Short for "unprocessed clause set", a shallow copy of C<cset>, keys will be
removed from here as they are processed by clause handlers, remaining keys after
processing the clause set means they are not recognized by hooks and thus
constitutes an error.

=item * B<ucsets> => ARRAY

All the C<ucset> for each clause set.

=item * B<clause> => STR

Current clause name.

=item * B<cl_meta> => HASH

Metadata information about the clause, from the clause definition. This include
C<prio> (priority), C<attrs> (list of attributes specific for this clause),
C<allow_expr> (whether clause allows expression in its value), etc. See
C<Data::Sah::Type::$TYPENAME> for more information.

=item * B<cl_value> => ANY

Clause value. Note: for putting in generated code, use C<cl_term>.

=item * B<cl_term> => STR

Clause value term. If clause value is a literal (C<.is_expr> is false) then it
is produced by passing clause value to C<literal()>. Otherwise, it is produced
by passing clause value to C<expr()>.

=item * B<cl_is_expr> => STR

A shortcut for C<< $cd->{cset}{"${clause}.is_expr"} >>.

=item * B<cl_is_multi> => STR

A shortcut for C<< $cd->{cset}{"${clause}.is_multi"} >>.

=item * B<indent_level> => INT

Current level of indent when printing result using C<< $c->line() >>. 0 means
unindented.

=item * B<all_expr_vars> => ARRAY

All variables in all expressions in the current schema (and all of its
subschemas). Used internally by compiler. For example (XXX syntax not not
finalized):

 # schema
 [array => {of=>'str1', min_len=>1, 'max_len=' => '$min_len*3'},
  {def => {
      str1 => [str => {min_len=>6, 'max_len=' => '$min_len*2',
                       check=>'substr($_,0,1) eq "a"'}],
  }}]

 all_expr_vars => ['schema:///csets/0/min_len', # or perhaps .../min_len/value
                   'schema://str1/csets/0/min_len']

This data can be used to order the compilation of clauses based on dependencies.
In the above example, C<min_len> needs to be evaluated before C<max_len>
(especially if C<min_len> is an expression).

=back

Keys which contain compilation result:

=over 4

=item * B<ccls> => [HASH, ...]

Compiled clauses, collected during processing of schema's clauses. Each element
will contain the compiled code in the target language, error message, and other
information. At the end of processing, these will be joined together.

=item * B<result>

The final result. For most compilers, it will be string/text.

=back

=head3 Return value

The compilation data will be returned as return value. Main result will be in
the C<result> key. There is also C<ccls>, and subclasses may put additional
results in other keys. Final usable result might need to be pieced together from
these results, depending on your needs.

=head3 Hooks

By default this base compiler does not define any hooks; subclasses can define
hooks to implement their compilation process. Each hook will be passed
compilation data, and should modify or set the compilation data as needed. The
hooks that compile() will call at various points, in calling order, are:

=over 4

=item * $c->before_compile($cd)

Called once at the beginning of compilation.

If hook sets $cd->{SKIP_COMPILE} to true then the whole compilation
process will end (after_compile() will not even be called).

=item * $c->before_handle_type($cd)

=item * $th->handle_type($cd)

=item * $c->before_all_clauses($cd)

Called before calling handler for any clauses.

=item * $th->before_all_clauses($cd)

Called before calling handler for any clauses, after compiler's
before_all_clauses().

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

=item * $th->after_all_clauses($cd)

Called after all clauses have been compiled, before compiler's
after_all_clauses().

=item * $c->after_all_clauses($cd)

Called after all clauses have been compiled.

=item * $c->after_compile($cd)

Called at the very end before compiling process end.

=back

=head2 $c->get_th

=head2 $c->get_fsh

=cut
