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
__END__
# ABSTRACT: Schema for data structures

=head1 SYNOPSIS

Sample schemas:

 # integer, optional
 'int'

 # required integer
 'int*'

 # idem
 ['int', {req=>1}]

 # integer between 1 and 10
 ['int*', {min=>1, max=>10}]

 # array of integers between 1 and 10
 ['array*', {of=>['int*', between=>[1, 10]]}]

 # a byte (let's assign it to a new type 'byte')
 ['int', {between=>[0,255]}]

 # a byte that's divisible by 3
 ['byte', {div_by=>3}]

 # internally, it will become (clause sets added):
 ['int', {between=>[0,255]}, {div_by=>3}]

 # a byte that's divisible by 3 *and* 5
 ['byte', {div_by=>3}, {div_by=>5}]

 # same thing
 ['int', {between=>[0,255]}, {div_by=>3}, {div_by=>5}]

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
      '-keys' => {postcode=>undef},
      '+keys' => {
          zipcode: ['str*', len=>5, '^\d{5}$'],
          country: ['str*', is=>'US'],
      },
      '-req_keys' => [qw/postcode/],
      '+req_keys' => [qw/zipcode/],
  }]

Using this module:

 use Data::Sah;
 my $sah = Data::Sah->new;

 # get the perl compiler
 my $perlc = $sah->get_compiler('perl');

Then use the perl compiler (see L<Data::Sah::Compiler::perl> to generate
validators for schema. There's also an easier interface: L<Data::Sah::Easy>.


=head1 DESCRIPTION

B<IMPLEMENTATION NOTE: This is a very early release, with partial
implementation. Do not use this module yet.>

Sah is a schema language to validate data structures.

Features/highlights:

=over 4

=item * Schema expressed as data structure

Using data structure as schema simplifies schema parsing, enables easier
manipulation (composition, merging, etc) of schema. For your convenience, Sah
accepts a variety of forms and shortcuts, which will be converted into a
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

=item * Easy conversion to other programming language (Perl, etc)

Sah schema can be converted into Perl, JavaScript, and any other programming
language as long as a compiler for that language exists. This means you only
need to write schema once and use it to validate data anywhere. Compilation to
target language enables faster validation speed. The generated Perl/JavaScript
code can run without this module.

=item * Conversion into human description text

Sah schema can also be converted into human text, technically it's just another
compiler. This can be used to generate specification document, error messages,
etc directly from the schema. This saves you from having to write for many
common error messages (but you can supply your own when needed).

The human text is translateable and can be output in various forms (as a single
sentence, single paragraph, or multiple paragraphs) and formats (text, HTML, raw
markup).

=item * Ability to express pretty complex schema

Sah supports common types and a quite rich set of type attributes for each type.
You can flexibly specify valid/invalid ranges of values, dependencies, conflict
rules, etc. There are also filters/functions and expressions.

=item * Extensible

You can add your own types, type attributes, and functions if what you need is
not supported out of the box.

=item * Emphasis on reusability

You can define schemas in terms of other schemas. Example:

 # array of unique gmail addresses
 [array => {uniq => 1, of => [email => {match => qr/gmail\.com$/}]}]

In the above example, the schema is based on 'email'. Email can be a type or
just another schema:

  # definition of email
  [str => {match => ".+\@.+"}]

You can also define in terms of other schemas with some modification, a la OO
inheritance.

 # schema: even
 [int => {div_by=>2}]

 # schema: pos_even
 [even => {min=>0}]

In the above example, 'pos_even' is defined from 'even' with an additional
clause (min=>0). As a matter of fact you can also override and B<remove>
restrictions from your base schema, for even more flexibility.

 # schema: pos_even_or_odd
 [pos_even => {"!div_by"=>2}] # remove the divisible_by attribute

The above example makes 'even_or_odd' effectively equivalent to positive
integer.

See L<Data::Sah::Manual::Schema> for more about clause set merging.

=back

To get started, see L<Data::Sah::Manual::Tutorial>.

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
either string $str unchanged if there is no shortcuts found, or array form. Dies
on invalid input syntax.

Example:

 parse_string_shortcuts("int*") -> [int => {required=>1}]

Autoloaded.

=head2 $sah->normalize_schema($schema) => HASH

Normalize a schema into the hash form ({type=>..., clause_sets=>..., def=>...)
as well as do some sanity checks on it. Returns the normalized schema if
succeeds, or an error message string if fails.

Can also be used as a function.

Autoloaded.

=head2 $sah->normalize_var($var) => STR

Normalize a variable name in expression into its fully qualified/absolute form.

Autoloaded. Not yet implemented.

For example:

 [int => {min => 10, 'max=' => '2*$min'}]

$min in the above expression will be normalized as 'schema:/clause_sets/0/min'.

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

=head2 Why choose Data::Sah?

B<Flexibility>. Data::Sah comes out of the box with a rich set of types and
clauses. It supports functions, prefilters/postfilters, expressions, and custom
(& translated) error messages, among other things. It can validate nested and
circular data structures.

B<Portability>. Instead of mixing Perl in schema, Sah lets users specify
functions/expressions using a minilanguage (L<Language::Expr>) which in turn
will be converted into target languages (Perl, JavaScript, etc). While this is
slightly more cumbersome, it makes schema easier to port/compile to languages
other than Perl. The default type hierarchy is also more language-neutral
instead of being more Perl-specific like the Moose type system.

B<Validation speed>. Many other validation modules interpret schema on the fly,
but Data::Sah generates a Perl validator from your schema. This is one or more
orders of magniture faster.

B<Reusability>. The Sah schema language emphasizes reusability by: 1)
encouraging using the same schema in multiple target languages (Perl,
JavaScript, etc); 2) allowing a schema to be based on a parent schema (a la OO
inheritance), and allowing child schema to add/replace as well I<remove>
clauses.

B<Extensibility>. Sah makes it easy to add new types, type clauses, and
functions.

=head2 The name?

Sah is an Indonesian word, meaning 'valid' or 'legal'. It's short.

The previous incarnation of this module uses the namespace Data::Schema, started
in 2009. Since then, there are many added features, a few removed ones, some
syntax and terminology changes, thus the new name.


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
translations. $LANGCODE is 2-letter language code, or
2-letter+underscore+2-letter locale code (e.g. C<id> for Indonesian, C<zh_CN>
for Mandarin). Language submodules follows the organization of other modules,
e.g. Data::Sah::Lang::en::Type::int, Data::Sah::Lang::id::FuncSet::Core, etc.

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

