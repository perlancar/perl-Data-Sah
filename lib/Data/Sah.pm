package Data::Sah;

use 5.010;
use Moo;
use Log::Any qw($log);
use vars qw($AUTOLOAD);

# store Data::ModeMerge instance
has compilers    => (is => 'rw', default => sub { {} });
has _merger      => (is => 'rw');
has _var_enumer  => (is => 'rw');

our $type_re     = qr/\A(?:[A-Za-z_]\w*::)*[A-Za-z_]\w*\z/;
our $funcset_re  = qr/\A(?:[A-Za-z_]\w*::)*[A-Za-z_]\w*\z/;
our $compiler_re = qr/\A[A-Za-z_]\w*\z/;

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

    #$log->trace("<- get_compiler($module)");
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

sub DESTROY { }

sub AUTOLOAD {
    my ($pkg, $sub) = $AUTOLOAD =~ /(.+)::(.+)/;
    die "Undefined subroutine $AUTOLOAD"
        unless $sub =~ /^(
                            _dump|
                            normalize_schema|
                            parse_string_shortcuts
                        )$/x;
    $pkg =~ s!::!/!g;
    require "$pkg/al_$sub.pm";
    goto &$AUTOLOAD;
}

1;
# ABSTRACT: Schema for data structures

=head1 SYNOPSIS

Sample schemas:

 # integer, optional
 'int'

 # required integer
 'int*'

 # same thing
 ['int', {req=>1}]

 # integer between 1 and 10
 ['int*', {min=>1, max=>10}]

 # same thing, the curly brace is optional (unless for advanced stuff)
 ['int*', min=>1, max=>10]

 # array of integers between 1 and 10
 ['array*', {of=>['int*', between=>[1, 10]]}]

 # a byte (let's assign it to a new type 'byte')
 ['int', {between=>[0,255]}]

 # a byte that's divisible by 3
 ['byte', {div_by=>3}]

 # a byte that's divisible by 3 *and* 5
 ['byte', {'div_by+'=>[3, 5]}] # you can read this as: div_by *many*

 # same thing
 ['byte', {'div_by&'=>[3, 5]}]

 # a byte that's divisible by 3 *or* 5
 ['byte', {'div_by|'=>[3, 5]}]

 # a byte that's *in*divisible by 3
 ['byte', {'!div_by'=>3}] # you can read this as: *not* div_by

 # an address hash (let's assign it to a new type called 'address')
 ['hash' => {
     # recognized keys
     keys         => {
         line1        => ['str*', max_len => 80],
         line2        => ['str*', max_len => 80],
         city         => ['str*', max_len => 60],
         province     => ['str*', max_len => 60],
         postcode     => ['str*', len_between=>[4, 15], match=>'^[\w-]{4,15}$'],
         country      => ['str*', len => 2, match => '^[A-Z][A-Z]$'],
     },
     # keys that must exist in data
     req_keys     => [qw/line1 city province postcode country/],
  }]

  # a US address, let's base it on 'address' but change 'postcode' to 'zipcode'.
  # also, require country to be set to 'US'
  ['address' => {
      '[merge:-]keys' => {postcode=>undef},
      '[merge]keys' => {
          zipcode => ['str*', len=>5, '^\d{5}$'],
          country => ['str*', is=>'US'],
      },
      '[merge:-]req_keys' => [qw/postcode/],
      '[merge:+]req_keys' => [qw/zipcode/],
  }]

Using this module:

 use Data::Sah;
 my $sah = Data::Sah->new;

 # get compiler, e.g. perl
 my $perlc = $sah->get_compiler('perl');

Then use the compiler (e.g. see L<Data::Sah::Compiler::perl> for more details on
how to generate validator using the perl compiler). There's also an easier
interface: L<Data::Sah::Easy>.


=head1 DESCRIPTION

B<NOTE: This is a very early release, with minimal implementation and
specification still changing. Do NOT use this module yet.>

Sah is a schema language to validate data structures.

Features/highlights:

=over 4

=item * Pure data structure

A Sah schema is just a normal data structure. Using data structures as schemas
simplifies parsing and enables easier manipulation (composition, merging, etc)
of schemas as well validation of the schemas themselves. For your convenience,
Sah accepts a variety of forms and shortcuts, which will be converted into a
normalized data structure form.

Some examples of schema:

 # a string
 'str'

 # a required string
 'str*'

 # same thing
 [str => {req=>1}]

 # a 3x3 matrix of required integers
 [array => {req=>1, len=>3, of=>
   [array => {req=>1, len=>3, of=>
     'int*'}]}]

See L<Data::Sah::Manual::Schema> for full description of the syntax.

=item * Compilation

To validate data, Perl validator code is generated (compiled) from your schema.
This ensures full validation speed, at least one to two orders of magnitude
faster than interpreted validation. Compilers to other languages also exist,
e.g. JavaScript. This means you only need to write a schema once and use it to
validate data anywhere.

The generated validator code can run without this module.

=item * Natural language description

Sah schema can also be converted into human text (e.g. C<[int => {between=>[1,
10]}]> becomes "a number between 1 and 10"). Technically it's just another
compiler. This can be used to generate specification document, error messages,
etc directly from the schema. This saves you from having to write for many
common error messages (but you can supply your own when needed).

The human text is translateable and can be output in various forms (as a single
sentence, single paragraph, or multiple paragraphs) and formats (text, HTML).

=item * Power

Sah supports common types and a quite rich set of clauses (and clause
attributes) for each type, including range constraints, nested conditionals,
dependencies, conflict rules, etc. There are also filters/functions and
expressions.

=item * Extensibility

You can add your own types, type clauses, and functions if what you need is not
supported out of the box.

=item * Emphasis on reusability

You can define schemas in terms of other schemas. Example:

 # array of unique gmail addresses
 [array => {uniq => 1, of => [email => {match => qr/gmail\.com$/}]}]

In the above example, the schema is based on 'email'. Email can be a type or
just another schema:

  # definition of email
  [str => {match => ".+\@.+"}]

Another example:

 # schema: even
 [int => {div_by=>2}]

 # schema: pos_even
 [even => {min=>0}]

In the above example, 'pos_even' is defined from 'even' with an additional
clause (min=>0). As a matter of fact you can also override and B<remove>
constraints from your base schema, for even more flexibility.

 # schema: pos_even_or_odd
 [pos_even => {"[merge:!]div_by"=>2}] # remove the div_by clause

The above example makes C<pos_even_or_odd> effectively equivalent to positive
integer.

See L<Data::Sah::Manual::Schema> for more about clause set merging.

For schema-local definition, you can also define schemas within schemas:

 # dice_throws: array of dice throw results
 ["array*" => {of => 'dice_throw*'},
  {def => {
      dice_throw => [int => {between=>[1, 6]}],
  }},
 ]

The C<dice_throw> schema will only be visible from within the C<dice_throws>.

See L<Data::Sah::Manual::Schema> for more about base schema definitions.

=back

To get started, see L<Data::Sah::Manual::Tutorial> and L<Data::Sah::Easy>.

This module uses L<Moo> for object system and L<Log::Any> for logging.


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

=cut

=head2 $sah->parse_string_shortcuts($str) => STR/ARRAY

Parse string form shortcut notations, like "int*", "str[]", etc and return
either string C<$str> unchanged if there is no shortcuts found, or the array
form. Dies on invalid input syntax.

Example:

 parse_string_shortcuts("int*")  # [int => {req=>1}]

Autoloaded.

=head2 $sah->normalize_schema($schema) => HASH

Normalize a schema, e.g. change C<int*> into C<[int => {"req:", {value=>1}}]>,
as well as do some sanity checks on it. Returns the normalized schema if
succeeds, or an error message string if fails.

Can also be used as a function.

Autoloaded.

=head2 $sah->normalize_var($var) => STR

Normalize a variable name in expression into its fully qualified/absolute form.

Autoloaded. Not yet implemented.

For example:

 [int => {min => 10, 'max=' => '2*$min'}]

$min in the above expression will be normalized as C<schema:clauses.min.value>.

=head2 $sah->compile($compiler_name, %compiler_args) => STR

Basically just a shortcut for get_compiler() and send %compiler_args to the
particular compiler. Returns string code.

=head2 $sah->perl(%args) => STR

Shortcut for $sah->compile('perl', %args).

=head2 $sah->human(%args) => STR

Shortcut for $sah->compile('human', %args).

=head2 $sah->js(%args) => STR

Shortcut for $sah->compile('js', %args).


=head1 FAQ

=head2 Why use a schema (a.k.a "Turing tarpit")? Why not use pure Perl?

I'll leave it to others to debate DSL (like templating language, schema, etc) vs
pure Perl. But my principle is: if a DSL can save me significant amount of time,
keep my code clean and maintainable, even if it's not perfect (what is?), I'll
take it. 90% of the time, my schemas are some variations of the simple cases
like:

 'str*'
 [str => {len_between=>[1, 10], match=>'some regex'}]
 [str => {in => [qw/a b c and some other values/]}]
 [array => {of => 'some_other_type'}]
 [hash => {keys => {key1=>'some schema', ...}, req_keys => [qw/.../], ...}]

and writing schemas I<is> faster and less tedious/error-prone than writing
equivalent Perl code, plus Sah can generate JavaScript code and human
description text for me. For more complex validation I stay with Sah until it
starts to get unwieldy. It usually can go pretty far since I can add functions
and custom clauses to its types; it's for the rare and very complex validation
needs that I go pure Perl. Your mileage may vary.

=head2 What does 'Sah' mean?

Sah is an Indonesian word, meaning 'valid' or 'legal'. It's short.

The previous incarnation of this module uses the namespace L<Data::Schema>,
started in 2009.

=head2 Why a new name/module? Difference with Data::Schema?

There are enough incompatibilities between the two (some different syntaxes,
renamed clauses). Also, some terminology have been changed, e.g. "attribute"
become "clauses", "suffix" becomes "attributes". This warrants a new name.

Compared to Data::Schema, Sah always compiles schemas and there is much greater
flexibility in code generation (can generate different forms of code, can change
data term, can generate code to validate multiple schemas, etc). There is no
longer hash form, schema is either a string or an array. Some clauses have been
renamed (mostly, commonly used clauses are abbreviated, Huffman encoding
thingy), some removed (usually because they are replaced by a more general
solution), and new ones have been added.

If you use Data::Schema, I recommend you migrate to Data::Sah as I will not be
developing Data::Schema anymore. Sorry, there's currently no tool to convert
your Data::Schema schemas to Sah, but it should be relatively straightforward. I
recommend that you look into L<Data::Sah::Easy>.


=head1 MODULE ORGANIZATION

B<Data::Sah::Type::*> roles specifies a type, e.g. Data::Sah::Type::bool
specifies the bool type.

B<Data::Sah::FuncSet::*> roles specifies bundles of functions, e.g.
Data::Sah::FuncSet::Core specifies the core/standard functions.

B<Data::Sah::Compiler::$LANG::> is for compilers. Each compiler (if derived from
BaseCompiler) might further contain ::TH::* and ::FSH::* to implement
appropriate functionalities, e.g. Data::Sah::Compiler::perl::TH::bool is the
'bool' type handler for the Perl compiler and
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


=head1 SEE ALSO

=head2 Alternatives to Sah

B<Moose> has a type system. B<MooseX::Params::Validate>, among others, can
validate method parameters based on this.

Some other data validation and data schema modules on CPAN:
L<Data::FormValidator>, L<Params::Validate>, L<Data::Rx>, L<Kwalify>,
L<Data::Verifier>, L<Data::Validator>, L<JSON::Schema>, L<Validation::Class>.

=cut

