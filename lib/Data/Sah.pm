package Data::Sah;

use 5.010;
use Moo;
use Log::Any qw($log);

# VERSION

our $Log_Validator_Code = $ENV{LOG_SAH_VALIDATOR_CODE} // 0;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(normalize_schema gen_validator);

# store Data::Sah::Compiler::* instances
has compilers    => (is => 'rw', default => sub { {} });

has _merger      => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        require Data::ModeMerge;
        my $mm = Data::ModeMerge->new(config => {
            recurse_array => 1,
        });
        $mm->modes->{NORMAL}  ->prefix   ('merge.normal.');
        $mm->modes->{NORMAL}  ->prefix_re(qr/\Amerge\.normal\./);
        $mm->modes->{ADD}     ->prefix   ('merge.add.');
        $mm->modes->{ADD}     ->prefix_re(qr/\Amerge\.add\./);
        $mm->modes->{CONCAT}  ->prefix   ('merge.concat.');
        $mm->modes->{CONCAT}  ->prefix_re(qr/\Amerge\.concat\./);
        $mm->modes->{SUBTRACT}->prefix   ('merge.subtract.');
        $mm->modes->{SUBTRACT}->prefix_re(qr/\Amerge\.subtract\./);
        $mm->modes->{DELETE}  ->prefix   ('merge.delete.');
        $mm->modes->{DELETE}  ->prefix_re(qr/\Amerge\.delete\./);
        $mm->modes->{KEEP}    ->prefix   ('merge.keep.');
        $mm->modes->{KEEP}    ->prefix_re(qr/\Amerge\.keep\./);
        $mm;
    },
);

has _var_enumer  => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        require Language::Expr::Interpreter::VarEnumer;
        Language::Expr::Interpreter::VarEnumer->new;
    },
);

our $type_re        = qr/\A(?:[A-Za-z_]\w*::)*[A-Za-z_]\w*\z/;
our $clause_name_re = qr/\A[A-Za-z_]\w*\z/;
our $clause_re      = qr/\A[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*\z/;
our $attr_re        = $clause_re;
our $funcset_re     = qr/\A(?:[A-Za-z_]\w*::)*[A-Za-z_]\w*\z/;
our $compiler_re    = qr/\A[A-Za-z_]\w*\z/;
our $clause_attr_on_empty_clause_re = qr/\A(?:\.[A-Za-z_]\w*)+\z/;

# produce a 2-level copy of schema, so it's safe to add/delete/modify the
# normalized schema's clause set and extras (but clause set's and extras' values
# are still references to the original).
sub normalize_schema {
    require Scalar::Util;

    my $self;
    if (Scalar::Util::blessed($_[0])) {
        $self = shift;
    } else {
        $self = __PACKAGE__->new;
    }
    my ($s) = @_;

    my $ref = ref($s);
    if (!defined($s)) {

        die "Schema is missing";

    } elsif (!$ref) {

        my $has_req = $s =~ s/\*\z//;
        $s =~ $type_re or die "Invalid type syntax $s, please use ".
            "letter/digit/underscore only";
        return [$s, $has_req ? {req=>1} : {}, {}];

    } elsif ($ref eq 'ARRAY') {

        my $t = $s->[0];
        my $has_req = $t && $t =~ s/\*\z//;
        if (!defined($t)) {
            die "For array form, at least 1 element is needed for type";
        } elsif (ref $t) {
            die "For array form, first element must be a string";
        }
        $t =~ $type_re or die "Invalid type syntax $s, please use ".
            "letter/digit/underscore only";

        my $clset0;
        my $extras;
        if (defined($s->[1])) {
            if (ref($s->[1]) eq 'HASH') {
                $clset0 = $s->[1];
                $extras = $s->[2];
                die "For array form, there should not be more than 3 elements"
                    if @$s > 3;
            } else {
                # flattened clause set [t, c=>1, c2=>2, ...]
                die "For array in the form of [t, c1=>1, ...], there must be ".
                    "3 elements (or 5, 7, ...)"
                        unless @$s % 2;
                $clset0 = { @{$s}[1..@$s-1] };
            }
        } else {
            $clset0 = {};
        }

        # check clauses and parse shortcuts (!c, c&, c|, c=)
        my $clset = {};
        for my $c (sort keys %$clset0) {
            my $c0 = $c;

            my $v = $clset0->{$c};

            # ignore expression
            my $expr;
            if ($c =~ s/=\z//) {
                $expr++;
                # XXX currently can't disregard merge prefix when checking
                # conflict
                die "Conflict between '$c=' and '$c'" if exists $clset0->{$c};
                $clset->{"$c.is_expr"} = 1;
            }

            my $sc = "";
            my $cn;
            {
                my $errp = "Invalid clause name syntax '$c0'"; # error prefix
                if (!$expr && $c =~ s/\A!(?=.)//) {
                    die "$errp, syntax should be !CLAUSE"
                        unless $c =~ $clause_name_re;
                    $sc = "!";
                } elsif (!$expr && $c =~ s/(?<=.)\|\z//) {
                    die "$errp, syntax should be CLAUSE|"
                        unless $c =~ $clause_name_re;
                    $sc = "|";
                } elsif (!$expr && $c =~ s/(?<=.)\&\z//) {
                    die "$errp, syntax should be CLAUSE&"
                        unless $c =~ $clause_name_re;
                    $sc = "&";
                } elsif (!$expr && $c =~ /\A([^.]+)(?:\.(.+))?\((\w+)\)\z/) {
                    my ($c2, $a, $lang) = ($1, $2, $3);
                    die "$errp, syntax should be CLAUSE(LANG) or C.ATTR(LANG)"
                        unless $c2 =~ $clause_name_re &&
                            (!defined($a) || $a =~ $attr_re);
                    $sc = "(LANG)";
                    $cn = $c2 . (defined($a) ? ".$a" : "") . ".alt.lang.$lang";
                } elsif ($c !~ $clause_re &&
                             $c !~ $clause_attr_on_empty_clause_re) {
                    die "$errp, please use letter/digit/underscore only";
                }
            }

            # XXX can't disregard merge prefix when checking conflict
            if ($sc eq '!') {
                die "Conflict between clause shortcuts '!$c' and '$c'"
                    if exists $clset0->{$c};
                die "Conflict between clause shortcuts '!$c' and '$c|'"
                    if exists $clset0->{"$c|"};
                die "Conflict between clause shortcuts '!$c' and '$c&'"
                    if exists $clset0->{"$c&"};
                $clset->{$c} = $v;
                $clset->{"$c.op"} = "not";
            } elsif ($sc eq '&') {
                die "Conflict between clause shortcuts '$c&' and '$c'"
                    if exists $clset0->{$c};
                die "Conflict between clause shortcuts '$c&' and '$c|'"
                    if exists $clset0->{"$c|"};
                die "Clause 'c&' value must be an array"
                    unless ref($v) eq 'ARRAY';
                $clset->{$c} = $v;
                $clset->{"$c.op"} = "and";
            } elsif ($sc eq '|') {
                die "Conflict between clause shortcuts '$c|' and '$c'"
                    if exists $clset0->{$c};
                die "Clause 'c|' value must be an array"
                    unless ref($v) eq 'ARRAY';
                $clset->{$c} = $v;
                $clset->{"$c.op"} = "or";
            } elsif ($sc eq '(LANG)') {
                die "Conflict between clause '$c' and '$cn'"
                    if exists $clset0->{$cn};
                $clset->{$cn} = $v;
            } else {
                $clset->{$c} = $v;
            }

        }
        $clset->{req} = 1 if $has_req;

        if (defined $extras) {
            die "For array form with 3 elements, extras must be hash"
                unless ref($extras) eq 'HASH';
            die "'def' in extras must be a hash"
                if exists $extras->{def} && ref($extras->{def}) ne 'HASH';
            return [$t, $clset, { %{$extras} }];
        } else {
            return [$t, $clset, {}];
        }
    }

    die "Schema must be a string or arrayref (not $ref)";
}

sub gen_validator {
    require Scalar::Util;
    require SHARYANTO::String::Util;

    my $self;
    if (Scalar::Util::blessed($_[0])) {
        $self = shift;
    } else {
        $self = __PACKAGE__->new;
    }

    my ($schema, $opts0) = @_;
    my %copts = %{$opts0 // {}};
    my $opt_source = delete $copts{source};
    my $aref       = delete $copts{accept_ref};
    $copts{schema}       = $schema;
    $copts{indent_level} = 1;
    $copts{data_name}    = 'data';

    my $vt;
    if ($aref) {
        $vt = '$ref_data';
        $copts{data_term} = '$$ref_data';
    } else {
        $vt = '$data';
        $copts{data_term} = '$data';
    }

    my $do_log = $copts{debug_log} || $copts{debug};
    my $vrt    = $copts{return_type} // 'bool';
    my $dt     = $copts{data_term};

    my $pl = $self->get_compiler("perl");
    my $cd;
    {
        # avoid logging displaying twice
        local $Log_Validator_Code = 0 if $Log_Validator_Code;
        $cd = $pl->compile(%copts);
    }

    my @code;
    if ($do_log) {
        push @code, "use Log::Any qw(\$log);\n";
    }
    push @code, "require $_;\n" for @{ $cd->{modules} };
    push @code, "sub {\n";
    push @code, "    my ($vt) = \@_;\n";
    push @code, "    my \$$_ = ".$pl->literal($cd->{vars}{$_}).";\n"
        for sort keys %{ $cd->{vars} };
    if ($do_log) {
        push @code, "    \$log->tracef('-> (validator)(%s) ...', $dt);\n";
        # str/full also need this, to avoid "useless ... in void context" warn
    }
    if ($vrt ne 'bool') {
        push @code, '    my $err_data = '.($vrt eq 'str' ? "undef":"{}").";\n";
    }
    push @code, "    my \$res = \n";
    push @code, $cd->{result};
    if ($vrt eq 'bool') {
        if ($do_log) {
            push @code, ";\n    \$log->tracef('<- validator() = %s', \$res)";
        }
        push @code, ";\n    return \$res";
    } else {
        if ($vrt eq 'str') {
            push @code, ";\n    \$err_data //= ''";
        }
        if ($do_log) {
            push @code, ";\n    \$log->tracef('<- validator() = %s', ".
                "\$err_data)";
        }
        push @code, ";\n    return \$err_data";
    }
    push @code, ";\n}\n";

    my $code = join "", @code;
    return $code if $opt_source;
    if ($Log_Validator_Code && $log->is_trace) {
        $log->tracef("validator code:\n%s",
                     ($ENV{LINENUM} // 1) ?
                         SHARYANTO::String::Util::linenum($code) :
                               $code);
    }

    my $res = eval $code;
    die "Can't compile validator: $@" if $@;
    $res;
}

sub _merge_clause_sets {
    my ($self, @clause_sets) = @_;
    my @merged;

    my $mm = $self->_merger;

    my @c;
    for (@clause_sets) {
        push @c, {cs=>$_, has_prefix=>$mm->check_prefix_on_hash($_)};
    }
    for (reverse @c) {
        if ($_->{has_prefix}) { $_->{last_with_prefix} = 1; last }
    }

    my $i = -1;
    for my $c (@c) {
        $i++;
        if (!$i || !$c->{has_prefix} && !$c[$i-1]{has_prefix}) {
            push @merged, $c->{cs};
            next;
        }
        $mm->config->readd_prefix(
            ($c->{last_with_prefix} || $c[$i-1]{last_with_prefix}) ? 0 : 1);
        my $mres = $mm->merge($merged[-1], $c->{cs});
        die "Can't merge clause sets: $mres->{error}" unless $mres->{success};
        $merged[-1] = $mres->{result};
    }
    \@merged;
}

sub get_compiler {
    my ($self, $name) = @_;
    return $self->compilers->{$name} if $self->compilers->{$name};

    die "Invalid compiler name `$name`" unless $name =~ $compiler_re;
    my $module = "Data::Sah::Compiler::$name";
    if (!eval "require $module; 1") {
        die "Can't load compiler module $module".($@ ? ": $@" : "");
    }

    my $obj = $module->new(main => $self);
    $self->compilers->{$name} = $obj;

    return $obj;
}

sub normalize_var {
    my ($self, $var, $curpath) = @_;
    die "Not yet implemented";
}

1;
# ABSTRACT: Fast and featureful data structure validation

=head1 SYNOPSIS

Non-OO interface:

 use Data::Sah qw(
     normalize_schema
     gen_validator
 );

 # generate a validator for schema
 my $v = gen_validator(["int*", min=>1, max=>10]);

 # validate your data using the generated validator
 say "valid" if $v->(5);     # valid
 say "valid" if $->(11);     # invalid
 say "valid" if $v->(undef); # invalid
 say "valid" if $v->("x");   # invalid

 # generate validator which reports error message string, in Indonesian
 my $v = gen_validator(["int*", min=>1, max=>10],
                       {return_type=>'str', lang=>'id_ID'});
 say $v->(5);  # ''
 say $v->(12); # 'Data tidak boleh lebih besar dari 10'
               # (in English: 'Data must not be larger than 10')

 # normalize a schema
 my $nschema = normalize_schema("int*"); # => ["int", {req=>1}, {}]

OO interface (more advanced usage):

 use Data::Sah;
 my $sah = Data::Sah->new;

 # get perl compiler
 my $pl = $sah->get_compiler("perl");

 # compile schema into Perl code
 my $cd = $pl->compile(schema => $schema, ...);


=head1 STATUS

Early implementation, some features are not implemented yet. Below is a list of
things that are not yet implemented:

=over

=item * human compiler

=over

=item * markdown output

=back

=item * js compiler

not yet implemented.

=item * perl compiler

=over

=item * def/subschema

=item * expression

=item * buf type

=item * date/datetime type

=item * obj: methods, attrs properties

=item * .prio, .err_msg, .ok_err_msg attributes

=item * .result_var attribute

=item * BaseType: ok, clset, if, prefilters, postfilters, check, prop, check_prop

=item * HasElems: each_elem, each_index, check_each_elem, check_each_index, exists

=item * HasElems: len, elems, indices properties

=item * hash: re_keys, each_key, each_value, check_each_key, check_each_value, allowed_keys, allowed_keys_re

=item * array: has, uniq

=back

=back


=head1 DESCRIPTION

This module, L<Data::Sah>, implements compilers for producing Perl and
JavaScript validators, as well as translatable human description text from
L<Sah> schemas. Compiler approach is used instead of interpreter for faster
speed.

The generated validator code can run without this module.


=head1 EXPORTS

None exported by default.

=head2 normalize_schema($schema) => ARRAY

Normalize C<$schema>.

Can also be used as a method.

=head2 gen_validator($schema, \%opts) => CODE (or STR)

Generate validator code for C<$schema>. Can also be used as a method. Known
options (unknown options will be passed to Perl schema compiler):

=over

=item * accept_ref => BOOL (default: 0)

Normally the generated validator accepts data, as in:

 $res = $vdr->($data);
 $res = $vdr->(42);

If this option is set to true, validator accepts reference to data instead, as
in:

 $res = $vdr->(\$data);

This allows $data to be modified by the validator (mainly, to set default value
specified in schema). For example:

 my $data;
 my $vdr = gen_validator([int => {min=>0, max=>10, default=>5}],
                         {accept_ref=>1});
 my $res = $vdr->(\$data);
 say $res;  # => 1 (success)
 say $data; # => 5

=item * source => BOOL (default: 0)

If set to 1, return source code string instead of compiled subroutine. Usually
only needed for debugging (but see also C<$Log_Validator_Code> and
C<LOG_SAH_VALIDATOR_CODE> if you want to log validator source code).

=back


=head1 ATTRIBUTES

=head2 compilers => HASH

A mapping of compiler name and compiler (Data::Sah::Compiler::*) objects.


=head1 VARIABLES

=head2 C<$Log_Validator_Code> (bool, default: 0)


=head1 ENVIRONMENT

L<LOG_SAH_VALIDATOR_CODE>


=head1 METHODS

=head2 new() => OBJ

Create a new Data::Sah instance.

=head2 $sah->get_compiler($name) => OBJ

Get compiler object. C<Data::Sah::Compiler::$name> will be loaded first and
instantiated if not already so. After that, the compiler object is cached.

Example:

 my $plc = $sah->get_compiler("perl"); # loads Data::Sah::Compiler::perl

=head2 $sah->normalize_schema($schema) => HASH

Normalize a schema, e.g. change C<int*> into C<< [int => {req=>1}] >>, as well
as do some sanity checks on it. Returns the normalized schema if succeeds, or
dies on error.

Can also be used as a function.

=head2 $sah->normalize_var($var) => STR

Normalize a variable name in expression into its fully qualified/absolute form.

Not yet implemented (pending specification).

For example:

 [int => {min => 10, 'max=' => '2*$min'}]

$min in the above expression will be normalized as C<schema:clauses.min>.

=head2 $sah->gen_validator($schema, \%opts) => CODE

Use the Perl compiler to generate validator code. Can also be used as a
function. See the documentation as a function for list of known options.


=head1 MODULE ORGANIZATION

B<Data::Sah::Type::*> roles specify Sah types, e.g. C<Data::Sah::Type::bool>
specifies the bool type. It can also be used to name distributions that
introduce new types, e.g. C<Data-Sah-Type-complex> which introduces complex
number type.

B<Data::Sah::FuncSet::*> roles specify bundles of functions, e.g.
<Data::Sah::FuncSet::Core> specifies the core/standard functions.

B<Data::Sah::Compiler::$LANG::> namespace is for compilers. Each compiler might
further contain <::TH::*> and <::FSH::*> subnamespaces to implement appropriate
functionalities, e.g. C<Data::Sah::Compiler::perl::TH::bool> is the bool type
handler for the Perl compiler and C<Data::Sah::Compiler::perl::FSH::Core> is the
Core funcset handler for Perl compiler.

B<Data::Sah::TypeX::$TYPENAME::$CLAUSENAME> namespace can be used to name
distributions that extend an existing Sah type by introducing a new clause for
it. See L<Data::Sah::Manual::Extending> for an example.

B<Data::Sah::Lang::$LANGCODE> namespaces are for modules that contain
translations. They are further organized according to the organization of other
Data::Sah modules, e.g. L<Data::Sah::Lang::en_US::Type::int> or
C<Data::Sah::Lang::en_US::TypeX::str::is_palindrome>.

B<Data::Sah::Schema::> namespace is reserved for modules that contain bundles of
schemas. For example, C<Data::Sah::Schema::CPANMeta> contains the schema to
validate CPAN META.yml. L<Data::Sah::Schema::Sah> contains the schema for Sah
schema itself.


=head1 FAQ

=head2 Relation to Data::Schema?

L<Data::Schema> is the old incarnation of this module, deprecated since 2011.

There are enough incompatibilities between the two (some different syntaxes,
renamed clauses). Also, some terminology have been changed, e.g. "attribute"
become "clauses", "suffix" becomes "attributes". This warrants a new name.

Compared to Data::Schema, Sah always compiles schemas and there is much greater
flexibility in code generation (can generate data term, can generate code to
validate multiple schemas, etc). There is no longer hash form, schema is either
a string or an array. Some clauses have been renamed (mostly, commonly used
clauses are abbreviated, Huffman encoding thingy), some removed (usually because
they are replaced by a more general solution), and new ones have been added.

If you use Data::Schema, I recommend you migrate to Data::Sah as I will not be
developing Data::Schema anymore. Sorry, there's currently no tool to convert
your Data::Schema schemas to Sah, but it should be relatively straightforward.

=head2 Comparison to {JSON::Schema, Data::Rx, Data::FormValidator, ...}?

See L<Sah::FAQ>.

=head2 Why is it so slow?

You probably do not reuse the compiled schema, e.g. you continually destroy and
recreate Data::Sah object, or repeatedly recompile the same schema. To gain the
benefit of compilation, you need to keep the compiled result and use the
generated Perl code repeatedly.

=head2 Can I generate another schema dynamically from within the schema?

For example:

 // if first element is an integer, require the array to contain only integers,
 // otherwise require the array to contain only strings.
 ["array", {"min_len": 1, "of=": "[is_int($_[0]) ? 'int':'str']"}]

Currently no, Data::Sah does not support expression on clauses that contain
other schemas. In other words, dynamically generated schemas are not supported.
To support this, if the generated code needs to run independent of Data::Sah, it
needs to contain the compiler code itself (or an interpreter) to compile or
evaluate the generated schema.

However, an C<eval_schema()> Sah function which uses Data::Sah can be trivially
declared and target the Perl compiler.

=head2 How to display the Perl (JavaScript, ...) validator code being generated?

If you compile using one of the compiler, e.g.:

 # generate perl code
 $cd = $plc->compile(schema=>..., ...);

then the Perl code is in C<< $cd->{result} >> and you can just print it.

If you generate validator using C<gen_validator()>, you can set environment
LOG_SAH_VALIDATOR_CODE or package variable $Log_Validator_Code to true and the
generated code will be logged at trace level using L<Log::Any>. The log can be
displayed using, e.g., L<Log::Any::App>:

 % LOG_SAH_VALIDATOR_CODE=1 TRACE=1 \
   perl -MLog::Any::App -MData::Sah=gen_validator \
   -e '$sub = gen_validator([int => min=>1, max=>10])'


=head1 SEE ALSO

=head2 Alternatives to Sah

B<Moose> has a type system. B<MooseX::Params::Validate>, among others, can
validate method parameters based on this.

Some other data validation and data schema modules on CPAN:
L<Data::FormValidator>, L<Params::Validate>, L<Data::Rx>, L<Kwalify>,
L<Data::Verifier>, L<Data::Validator>, L<JSON::Schema>, L<Validation::Class>.

=cut

