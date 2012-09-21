package Data::Sah;

use 5.010;
use Moo;
use Log::Any qw($log);

# VERSION

# store Data::Sah::Compiler::* instances
has compilers    => (is => 'rw', default => sub { {} });

# store Data::ModeMerge instance
has _merger      => (is => 'rw');

# store Language::Expr::Interpreter::VarEnumber instance
has _var_enumer  => (is => 'rw');

our $type_re     = qr/\A(?:[A-Za-z_]\w*::)*[A-Za-z_]\w*\z/;
our $clause_re   = qr/\A[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*\z/;
our $funcset_re  = qr/\A(?:[A-Za-z_]\w*::)*[A-Za-z_]\w*\z/;
our $compiler_re = qr/\A[A-Za-z_]\w*\z/;
our $clause_attr_on_empty_clause_re = qr/\A(?:\.[A-Za-z_]\w*)+\z/;

sub _dump {
    require Data::Dump::OneLine;

    my $self = shift;
    return Data::Dump::OneLine::dump_one_line(@_);
}

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
        return [$s, $has_req ? {req=>1} : {}];

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

        my $cset0;
        my $extras;
        if (defined($s->[1])) {
            if (ref($s->[1]) eq 'HASH') {
                $cset0 = $s->[1];
                $extras = $s->[2];
                die "For array form, there should not be more than 3 elements"
                    if @$s > 3;
            } else {
                # flattened clause set [t, c=>1, c2=>2, ...]
                die "For array in the form of [t, c1=>1, ...], there must be ".
                    "3 elements (or 5, 7, ...)"
                        unless @$s % 2;
                $cset0 = { @{$s}[1..@$s-1] };
            }
        } else {
            $cset0 = {};
        }

        # check clauses and parse shortcuts (!c, c&, c|, c=)
        my $cset = {};
        for my $c (sort keys %$cset0) {
            my $c0 = $c;

            my $v = $cset0->{$c};

            # ignore merge prefix
            my $mp = "";
            $c =~ s/\A(\[merge[!^+.-]?\])// and $mp = $1;

            # ignore (defhash spec)

            # ignore expression
            my $expr;
            if ($c =~ s/=\z//) {
                $expr++;
                # XXX currently can't disregard merge prefix when checking
                # conflict
                die "Conflict between '$c=' and '$c'" if exists $cset0->{$c};
                $cset->{"$c.is_expr"} = 1;
            }

            my $sc = "";
            if (!$mp && !$expr && $c =~ s/\A!(?=.)//) {
                $sc = "!";
            } elsif (!$mp && !$expr && $c =~ s/(?<=.)\|\z//) {
                $sc = "|";
            } elsif (!$mp && !$expr && $c =~ s/(?<=.)\&\z//) {
                $sc = "&";
            } elsif ($c !~ $clause_re &&
                         $c !~ $clause_attr_on_empty_clause_re) {
                die "Invalid clause name syntax '$c0', please use ".
                    "letter/digit/underscore only";
            }

            # XXX can't disregard merge prefix when checking conflict
            if ($sc eq '!') {
                die "Conflict between clause shortcuts '!$c' and '$c'"
                    if exists $cset0->{$c};
                die "Conflict between clause shortcuts '!$c' and '$c|'"
                    if exists $cset0->{"$c|"};
                die "Conflict between clause shortcuts '!$c' and '$c&'"
                    if exists $cset0->{"$c&"};
                $cset->{$c} = $v;
                $cset->{"$c.max_ok"} = 0;
            } elsif ($sc eq '&') {
                die "Conflict between clause shortcuts '$c&' and '$c'"
                    if exists $cset0->{$c};
                die "Conflict between clause shortcuts '$c&' and '$c|'"
                    if exists $cset0->{"$c|"};
                die "Clause 'c&' value must be an array"
                    unless ref($v) eq 'ARRAY';
                $cset->{"$c.vals"} = $v;
            } elsif ($sc eq '|') {
                die "Conflict between clause shortcuts '$c|' and '$c'"
                    if exists $cset0->{$c};
                die "Clause 'c|' value must be an array"
                    unless ref($v) eq 'ARRAY';
                $cset->{"$c.vals"} = $v;
                $cset->{"$c.min_ok"} = 1;
            } else {
                $cset->{"$mp$c"} = $v;
            }

        }
        $cset->{req} = 1 if $has_req;

        if (defined $extras) {
            die "For array form with 3 elements, extras must be hash"
                unless ref($extras) eq 'HASH';
            die "'def' in extras must be a hash"
                if exists $extras->{def} && ref($extras->{def}) ne 'HASH';
            return [$t, $cset, $extras];
        } else {
            return [$t, $cset];
        }
    }

    die "Schema must be a string or arrayref (not $ref)";
}

sub _merge_clause_sets {
    require Data::ModeMerge;

    my ($self, @clause_sets) = @_;
    my @merged;

    my $mm = $self->_merger;
    if (!$mm) {
        $mm = Data::ModeMerge->new(config => {
            recurse_array => 1,
        });
        $mm->modes->{NORMAL}  ->prefix   ('[merge]');
        $mm->modes->{NORMAL}  ->prefix_re(qr/\A\[merge\]/);
        $mm->modes->{ADD}     ->prefix   ('[merge+]');
        $mm->modes->{ADD}     ->prefix_re(qr/\A\[merge\+\]/);
        $mm->modes->{CONCAT}  ->prefix   ('[merge.]');
        $mm->modes->{CONCAT}  ->prefix_re(qr/\A\[merge\.\]/);
        $mm->modes->{SUBTRACT}->prefix   ('[merge-]');
        $mm->modes->{SUBTRACT}->prefix_re(qr/\A\[merge-\]/);
        $mm->modes->{DELETE}  ->prefix   ('[merge!]');
        $mm->modes->{DELETE}  ->prefix_re(qr/\A\[merge!\]/);
        $mm->modes->{KEEP}    ->prefix   ('[merge^]');
        $mm->modes->{KEEP}    ->prefix_re(qr/\A\[merge\^\]/);
        $self->_merger($mm);
    }

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
    $log->trace("-> get_compiler($name)");
    return $self->compilers->{$name} if $self->compilers->{$name};

    die "Invalid compiler name `$name`" unless $name =~ $compiler_re;
    my $module = "Data::Sah::Compiler::$name";
    if (!eval "require $module; 1") {
        die "Can't load compiler module $module".($@ ? ": $@" : "");
    }

    my $obj = $module->new(main => $self);
    $self->compilers->{$name} = $obj;

    $log->trace("<- get_compiler($module)");
    return $obj;
}

sub normalize_var {
    my ($self, $var, $curpath) = @_;
    die "Not yet implemented";
}

sub compile {
    my ($self, $compiler_name, %args) = @_;
    my $c = $self->get_compiler($compiler_name);
    $c->compile(%args);
}

sub perl {
    my ($self, %args) = @_;
    return $self->compile('perl', %args);
}

sub human {
    my ($self, %args) = @_;
    return $self->compile('human', %args);
}

sub js {
    my ($self, %args) = @_;
    return $self->compile('js', %args);
}

1;
# ABSTRACT: Schema for data structures (Perl implementation)

=head1 SYNOPSIS

First, familiarize with the schema syntax. Refer to L<Sah> and L<Sah::Examples>.
Some example schemas:

 'int'                       # an optional integer
 'int*'                      # a required integer
 [int => {min=>1, max=>10}]  # an integer with some constraints

To use this module:

 use Data::Sah;
 my $sah = Data::Sah->new;

 # get compiler, e.g. perl
 my $perlc = $sah->get_compiler('perl');

 # use the compiler to generate code
 my $code = $perlc->compile(
     inputs => [
         {name   => 'data',
          term   => '\%data',
          schema => ['hash*' => {keys_between => [1, 10]}],
          lvalue => 0},
         {name   => 'data_len',
          term   => 'scalar(keys %data)',
          schema => ['int*' => {between => [1, 10]}],
          lvalue => 0},
     ],
 );

 my %data = (a => 1);

 # use the generated code
 eval $code;

See also an easier interface: L<Data::Sah::Easy>.


=head1 DESCRIPTION

This module, L<Data::Sah>, implements compilers for producing Perl and
JavaScript validators, as well as human description text (English and Indonesian
included) from L<Sah> schemas. Compiler approach is used instead of interpreter
for faster speed.

The generated validator code can run without this module.


=head1 ATTRIBUTES

=head2 compilers => HASH

A mapping of compiler name and compiler (Data::Sah::Compiler::*) objects.


=head1 METHODS

=head2 new() => OBJ

Create a new Data::Sah instance.

=head2 $sah->get_compiler($name) => OBJ

Get compiler object. "Data::Sah::Compiler::$name" will be loaded first and
instantiated if not already so. After that, the compiler object is cached.

Example:

 my $plc = $sah->get_compiler("perl"); # loads Data::Sah::Compiler::perl

=head2 $sah->normalize_schema($schema) => HASH

Normalize a schema, e.g. change C<int*> into C<[int => {req=>1}]>, as well as do
some sanity checks on it. Returns the normalized schema if succeeds, or dies on
error.

Can also be used as a function.

=head2 $sah->normalize_var($var) => STR

Normalize a variable name in expression into its fully qualified/absolute form.

Not yet implemented (pending specification).

For example:

 [int => {min => 10, 'max=' => '2*$min'}]

$min in the above expression will be normalized as C<schema:clauses.min>.

=head2 $sah->compile($compiler_name, %compiler_args) => STR

Basically just a shortcut for get_compiler() and send %compiler_args to the
particular compiler. Returns generated code.

=head2 $sah->perl(%args) => STR

Shortcut for $sah->compile('perl', %args).

=head2 $sah->human(%args) => STR

Shortcut for $sah->compile('human', %args).

=head2 $sah->js(%args) => STR

Shortcut for $sah->compile('js', %args).


=head1 MODULE ORGANIZATION

B<Data::Sah::Type::*> roles specify Sah types, e.g. Data::Sah::Type::bool
specifies the bool type.

B<Data::Sah::FuncSet::*> roles specify bundles of functions, e.g.
Data::Sah::FuncSet::Core specifies the core/standard functions.

B<Data::Sah::Compiler::$LANG::> namespace is for compilers. Each compiler (if
derived from BaseCompiler) might further contain ::TH::* and ::FSH::* to
implement appropriate functionalities, e.g. Data::Sah::Compiler::perl::TH::bool
is the 'bool' type handler for the Perl compiler and
Data::Sah::Compiler::perl::FSH::Core is the funcset 'Core' handler for Perl
compiler.

B<Data::Sah::Lang::$LANGCODE::*> namespace is reserved for modules that contain
translations. Language submodules follows the organization of other modules,
e.g. Data::Sah::Lang::en_US::Type::int, Data::Sah::Lang::id_ID::FuncSet::Core,
etc.

B<Data::Sah::Schema::> namespace is reserved for modules that contain bundles of
schemas. For example, L<Data::Sah::Schema::CPANMeta> contains the schema to
validate CPAN META.yml. L<Data::Sah::Schema::Sah> contains the schema for Sah
schema itself.

B<Data::Sah::TypeX::$TYPENAME::$CLAUSENAME> namespace can be used to name
distributions that extend an existing Sah type by introducing a new clause for
it. It must also contain, at the minimum: perl, js, and human compiler
implementations for it, as well as English translations. For example,
Data::Sah::TypeX::int::is_prime is a distribution that adds C<is_prime> clause
to the C<int> type. It will contain the following packages inside:
Data::Sah::Type::int, Data::Sah::Compiler::{perl,human,js}::TH::int. Other
compilers' implementation can be packaged under
B<Data::Sah::Compiler::$COMPILERNAME::TypeX::$TYPENAME::$CLAUSENAME>, e.g.
Data::Sah::Compiler::python::TypeX::int::is_prime distribution. Language can be
put in B<Data::Sah::Lang::$LANGCODE::TypeX::int::is_prime>.

B<Data::Sah::Manual::*> contains documentation, surprisingly enough.


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
your Data::Schema schemas to Sah, but it should be relatively straightforward. I
recommend that you look into L<Data::Sah::Easy>.

=head2 Comparison to ...?

TBD

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
declared in Perl.


=head1 SEE ALSO

=head2 Alternatives to Sah

B<Moose> has a type system. B<MooseX::Params::Validate>, among others, can
validate method parameters based on this.

Some other data validation and data schema modules on CPAN:
L<Data::FormValidator>, L<Params::Validate>, L<Data::Rx>, L<Kwalify>,
L<Data::Verifier>, L<Data::Validator>, L<JSON::Schema>, L<Validation::Class>.

=cut

