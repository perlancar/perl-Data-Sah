package Data::Sah;
# ABSTRACT: Schema for data structures

use 5.010;
use Any::Moose;
use AutoLoader 'AUTOLOAD';
use Log::Any qw($log);

our $type_re    = /\A[A-Za-z_]\w*\z/;
our $emitter_re = /\A[A-Za-z_]\w*\z/;

=head1 ATTRIBUTES

=cut

has merger => (
    is      => 'rw',
);

# key = emitter name, value = emitter object
has emitters => (
    is      => 'rw',
    default => sub { {} },
);

# key = typename, value = ROLENAME (str) or SCHEMA (hash)
has types => (
    is      => 'rw',
    default => sub { {} },
);

our @default_plugins = ("");

has plugins => (
    is      => 'rw',
    default => sub { [] },
);

our @default_lang_module_prefixes = ("");

# element = fully qualified module name
has lang_module_prefixes => (
    is      => 'rw',
    default => sub { [] },
);

our @default_func_sets = ("Core");

# key = set (namespace) name, value = object
has func_sets => (
    is      => 'rw',
    default => sub { {} },
);

=head2 merge_clause_sets => BOOL

Whether to merge clause sets when multiple sets are specified in the schema and
the second+ schema contains merge prefixes. By default this is turned on.

=cut

has merge_clause_sets => (
    is      => 'rw',
    default => 1,
);

=head1 METHODS

=cut

=head2 merge_clause_sets($clause_sets)

Merge several clause sets if there are sets that can be merged (i.e. contains
merge prefix in its keys).

=cut

=head2 load_plugin($module)

Load plugin module ("Data::Sah::Plugin::$module").

=cut

sub load_plugin {
    my ($self, $module) = @_;
    $log->trace("-> load_plugin($module)");

    die "Invalid plugin module name: $module"
		unless $module =~ /^\w+(::\w+)*\z/;
    my $prefix = "Data::Sah::Plugin::";
    $module = "$prefix$module" unless index($module, $prefix) == 0;

    # why would we want to limit one plugin instance per class?
    #return if grep { ref($_) eq $module } @{ $self->plugins };

    if (!eval "require $module; 1") {
        die "Can't load plugin module $module".($@ ? ": $@" : "");
    }

    my $obj = $module->new(main => $self);
    push @{ $self->plugins }, $obj;

    #$log->trace("<- load_plugin($module)");
}

sub _call_plugin_hook {
    my ($self, $name, @args) = @_;
    $name = "hook_$name" unless $name =~ /^hook_/;
    for my $p (@{ $self->plugins }) {
        if ($p->can($name)) {
            $log->tracef("Calling plugin: %s->%s(\@{ %s })",
                         ref($p), $name, \@args);
	    my $res = $p->$name(@args);
            $log->tracef("Result from plugin: %d", $res);
            return $res unless defined($res) && $res == -1;
        }
    }
    -1;
}

=head2 get_emitter($name) => $obj

Get emitter object. "Data::Sah::Emitter::$name" will be loaded first if not
already so.

Example:

 my $perl_emitter = $sah->get_emitter("perl"); # loads Data::Sah::Emitter::perl

=cut

sub get_emitter {
    my ($self, $name) = @_;
    $log->trace("-> get_emitter($name)");
    return $self->emitters->{$name} if $self->emitters->{$name};

    die "Invalid emitter name `$name`" unless $name =~ $emitter_re;
    my $module = "Data::Sah::Emitter::$name";
    if (!eval "require $module; 1") {
        die "Can't load plugin module $module".($@ ? ": $@" : "");
    }

    my $obj = $module->new(main => $self);
    $self->emitters->{$name} = $obj;

    #$log->trace("<- get_emitter($module)");
    return $obj;
}

=head2 register_schema_as_type($schema, $typename)

=cut

sub register_schema_as_type {
    my ($self, $schema, $typename) = @_;
    # XXX check syntax of typename, normalize schema, add into existing types
}

=head2 parse_string_shortcuts($str)

Parse string form shortcut notations, like "int*", "str[]", etc and return
either string $str unchanged if there is no shortcuts found, or array form, or
undef if there is an error.

Example: parse_string_shortcuts("int*") -> [int => {required=>1}]

=cut

=head2 normalize_schema($schema)

Normalize a schema into the hash form ({type=>..., clause_sets=>..., def=>...)
as well as do some sanity checks on it. Returns the normalized schema if
succeeds, or an error message string if fails.

=cut

=head2 normalize_var($var) -> STR

Normalize a variable name in expression into its fully qualified/absolute form.
For example: foo -> schema:/abs/path/foo.

 [int => {min => 10, 'max=' => '2*$min'}]

$min in the above expression will be normalized as 'schema:/attrs/min'.

Not yet implemented.

=cut

sub normalize_var {
    my ($self, $var, $curpath) = @_;
    $var;
}

=head2 is_func($name) -> BOOL

Check whether function named $name is known.

=cut

sub is_func {
    my ($self, $name) = @_;
    # XXX
}

=head2 emit($schema, $emitter_name, [$config])

Send schema to a specified emitter. Will try to load emitter first if not
already loaded.

=cut

sub emit {
    my ($self, $schema, $emitter_name, $config) = @_;
    my $e = $self->get_emitter($emitter_name);

    my %old_config;
    if ($config) {
        while (my ($k, $v) = each %$config) {
            $old_config{$k} = $e->$k;
            $e->$k($v);
        }
    }

    my $res = $e->emit($schema);

    while (my ($k, $v) = each %old_config) {
        $e->$k($v);
    }

    $res;
}

=head2 perl([$schema[, $config]])

Shortcut method. $sah->perl is equivalent to $sah->get_emitter('perl').
$sah->perl($schema[, $config]) is equivalent to $sah->emit($schema, 'perl'[,
$config]).

=cut

sub perl {
    my ($self, $schema, $config) = @_;
    return $self->get_emitter('perl') unless $schema;
    return $self->emit($schema, 'perl', $config);
}

=head2 human([$schema, $config]])

Shortcut method. $sah->human is equivalent to $sah->get_emitter('human').
$sah->human($schema[, $config]) is equivalent to $sah->emit($schema, 'human'[,
$config]).

=cut

sub human {
    my ($self, $schema, $config) = @_;
    return $self->get_emitter('human') unless $schema;
    return $self->emit($schema, 'human', $config);
}

=head2 js([$schema, $config]])

Shortcut method. $sah->js is equivalent to $sah->get_emitter('js').
$sah->js($schema[, $config]) is equivalent to $sah->emit($schema, 'js'[,
$config]).

=cut

sub js {
    my ($self, $schema, $config) = @_;
    return $self->get_emitter('js') unless $schema;
    return $self->emit($schema, 'js', $config);
}

=head2 compile($schema[, $config])

Compile the schema into Perl code and return a 2-element list: ($coderef,
$subname). $coderef is the resulting subroutine and $subname is the subroutine
name in the compilation namespace.

Die if code can't be generated, or an error occured when compiling the code.

If you want to get the Perl code in a string, use C<perl>.

=cut

sub compile {
    my ($self, $schema, $config) = @_;

    $schema = $self->normalize_schema($schema);
    die "Can't normalize schema: $schema" unless ref($schema);

    my $res = $self->emit($schema, 'perl', $config);
    eval $res->{code};
    my $eval_error = $@;
    if ($eval_error) {
        print STDERR $perl, $eval_error if $log->is_debug;
        die "Can't compile Perl code: $eval_error";
    }

    my $subfillname = $res->{subfullname};
    if (wantarray) {
        return (\&$subfullname, $subfullname);
    } else {
        return \&$subfullname;
    }
}

no Any::Moose;
1;
__END__
=pod

=head1 SYNOPSIS

 use Data::Sah;
 my $sah = Data::Sah->new;

 # compile schema to Perl sub
 my $schema = ['array*' => {minlen=>1, of=>'int*'}];
 my $sub = $sah->compile($schema);

 # validate data
 my $res;
 $res = $sub->([1, 2, 3]);
 die $res->errmsg if !$res->is_success; # OK
 $res = $sub->([1, 2, 3]);
 die $res->errmsg if !$res->is_success; # dies: 'Data not an array'

 # convert schema to JavaScript code (requires Data::Sah::Emitter::js)
 $schema = [int => {required=>1, min=>10, max=>99, divisible_by=>3}];
 print
   '<script>',
   $sah->js($schema, {name => '_validate'}),
   'function validate(data) {
      res = _validate(data)
      if (res.is_success) {
        return true
      } else {
        alert(res.errmsg)
        return false
      }
   }
   </script>
   <form onClick="return validate(this.form.data.value)">
     Please enter a number between 10 and 99 that is divisible by 3:
     <input name=data>
     <input type=submit>
   </form>';

=head1 DESCRIPTION

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
 [str => {required=>1}]

 # a 3x3 matrix of required integers
 [array => {required=>1, len=>3, of=>
   [array => {required=>1, len=>3, of=>
     'int*'}]}]

See L<Data::Sah::Manual::Schema> for full description of the syntax.

=item * Easy conversion to other programming language (Perl, etc)

Sah schema can be converted into Perl, JavaScript, and any other programming
language as long as an emitter for that language exists. This means you only
need to write schema once and use it to validate data anywhere. Compilation to
target language enables faster validation speed. The generated Perl/JavaScript
code can run without this module.

=item * Conversion into human description text

Sah schema can also be converted into human text, technically it's just another
emitter. This can be used to generate specification document, error messages,
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
 [array => {unique => 1, of => [email => {match => qr/gmail\.com$/}]}]

In the above example, the schema is based on 'email'. Email can be a type or
just another schema:

  # definition of email
  [str => {match => ".+\@.+"}]

You can also define in terms of other schemas with some modification, a la OO
inheritance.

 # schema: even
 [int => {divisible_by=>2}]

 # schema: pos_even
 [even => {min=>0}]

In the above example, 'pos_even' is defined from 'even' with an additional
clause (min=>0). As a matter of fact you can also override and B<remove>
restrictions from your base schema, for even more flexibility.

 # schema: pos_even_or_odd
 [pos_even => {"!divisible_by"=>2}] # remove the divisible_by attribute

The above example makes 'even_or_odd' effectively equivalent to positive
integer.

See L<Data::Sah::Manual::Schema> for more about clause set merging.

=back

To get started, see L<Data::Sah::Manual::Tutorial>.

=cut

=head1 FAQ

=head3 Why choose Sah over other data validation/schema/type system on CPAN?

B<Validation speed>. Many other modules interpret schema on the fly instead of
compiling it directly to Perl code. While this is sufficiently speedy for many
cases, it can be one order of magnitude or more slower than compiled schema.

B<Portability>. Sah supports functions and expressions using a minilanguage
which will be converted into target language, instead of letting user specify
direct Perl code in their schema. While this is a bit more cumbersome, it makes
schema easier to port/compile to languages other than Perl (e.g. JavaScript, to
generate client-side web form validation code). The type hierarchy is also more
language-neutral instead of being more Perl-specific like the Moose type system.

B<Syntax>. While syntax is largely a matter of taste, I have tried to make Sah
schema concise (e.g. through shortcuts) and convenient through alternate forms
easy and convenient to write by providing alternate forms, shortcuts, and
aliases for type/clause names.

=head3 Why the name?

Sah is an Indonesian word, meaning 'valid'. It's short.

The previous incarnation of this module uses the name Data::Schema. Since then,
there are many added features, a few removed ones, some syntax and terminology
changes, thus the new name.


=head1 MODULE ORGANIZATION

Sah::Type::* roles specifies a type, e.g. Sah::Type::Bool specifies the boolean
type.

Sah::Func::* roles specifies bundles of functions, e.g. Sah::Func::Core
specifies the core/standard functions.

Sah::Emitter::$LANG:: is for emitters. Each emitter might further contain
::Type::* and ::Func::* to implement appropriate functionalities, e.g.
Sah::Emitter::Perl::Type::Bool is the emitter for boolean.

Sah::Lang:: namespace is reserved for modules that contain translations. The
last part of the qualified name is the 2-letter language code.

Sah::Schema:: namespace is reserved for modules that contain bundles of schemas.
For example, L<Data::Sah::Schema::CPANMeta> contains the schema to validate CPAN
META.yml. L<Data::Sah::Schema::Schema> contains the schema for Sah schema
itself.

=head1 SEE ALSO

B<Moose> has a type system. B<MooseX::Params::Validate>, among others, can
validate method parameters based on this.

Some other data validation and data schema modules on CPAN:
L<Data::FormValidator>, L<Params::Validate>, L<Data::Rx>, L<Kwalify>,
L<Data::Verifier>, L<Data::Validator>, L<JSON::Schema>.

=cut
