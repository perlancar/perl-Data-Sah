package Sah;
# ABSTRACT: Schema for data structures

=head1 SYNOPSIS

 use Sah;
 my $sah = Sah->new;

 # compile schema to Perl sub
 my $schema = [array => {required=>1, minlen=>1, of=>'int*'}];
 my $sub = $sah->compile($schema);

 # validate data
 my $res;
 $res = $sub->([1, 2, 3]);
 die $res->errmsg if !$res->is_success; # OK
 $res = $sub->([1, 2, 3]);
 die $res->errmsg if !$res->is_success; # dies: 'Data not an array'

 # convert schema to JavaScript code (requires Sah::Emitter::JS)
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
accepts a variety of forms and shortcuts/aliases, which will be converted into a
normalized data structure form.

Some examples of schema:

 # a string
 'str'

 # a required string
 'str*'

 # same thing
 [str => {req=>1}]

 # a 3x3 matrix of required integers
 [array => {req=>1, len=>3, of=> [array => {req=>1, len=>3, of=>'int*'}]}]

See L<Sah::Manual::Schema> for full description of the syntax.

=item * Easy conversion to other programming language (Perl, etc)

Sah schema can be converted into Perl, JavaScript, and any other programming
language as long as an emitter for that language exists. This means you only need
to write schema once and use it to validate data anywhere. Compilation to target
language enables faster validation speed. The generated Perl/JavaScript code can
run without this module.

=item * Conversion into human description text

Sah schema can also be converted into human text, technically it's just another
emitter. This can be used to generate specification document, error messages, etc
directly from the schema. This saves you from having to write for many common
error messages (but you can supply your own when needed).

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

In the above example, the schema is based on 'email'. Email can be a type or just
another schema:

  # definition of email
  [str => {match => ".+\@.+"}]

You can also define in terms of other schemas with some modification, a la OO
inheritance.

 # schema: even
 [int => {divisible_by=>2}]

 # schema: pos_even
 [even => {min=>0}]

In the above example, 'pos_even' is defined from 'even' with an additional clause
(min=>0). As a matter of fact you can also override and B<remove> restrictions
from your base schema, for even more flexibility.

 # schema: pos_even_or_odd
 [pos_even => {"!divisible_by"=>2}] # remove the divisible_by attribute

The above example makes 'even_or_odd' effectively equivalent to positive integer.

See L<Sah::Manual::Schema> for more about clause set merging.

=back

To get started, see L<Sah::Manual::Tutorial>.

=cut

use 5.010;
use Any::Moose;
use AutoLoader 'AUTOLOAD';
use Log::Any qw($log);

=head1 ATTRIBUTES

=cut

has merger => (
    is      => 'rw',
);

our @default_emitters = (
    qw/
          Perl Human JS
      /);

has emitters => (
    is      => 'rw',
    default => sub { {} },
);

our @default_plugins = ("");

has plugins => (
    is      => 'rw',
    default => sub { [] },
);

our @default_type_roles = (
    qw/
          All Array Bool CIStr DateTime Either
          Float Hash Int Object Str
      /);

# element = fully qualified module name
has type_roles => (
    is      => 'rw',
    default => sub { [] },
);

# key = type name, value = role object OR schema
has type_names => (
    is       => 'rw',
    default => sub { {} },
);

our $default_lang_module_prefixes = ("");

# element = fully qualified module name
has lang_module_prefixes => (
    is      => 'rw',
    default => sub { [] },
);

our $default_func_sets = ("Core");

# key = set (namespace) name, value = object
has func_roles => (
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

=head2 register_emitter($module)

Load emitter. $module will be prefixed by "Sah::Emitter::" (unless it's prefixed
by "^").

Example:

 $sah->register_emitter('JS');        # registers Sah::Emitter::JS
 $sah->register_emitter('^Foo::Bar'); # registers Foo::Bar

Will be called automatically for all the default emitters (Human and Perl), or by
emit() when an unloaded emitter is requested, or if you request it when importing
Sah:

=cut

sub register_emitter {
    my ($self, $module) = @_;

    $log->trace("-> register_emitter($module)");

    if ($module =~ /^\^(.+)/) {
        $module = $1;
    } else {
        $module = "Sah::Emitter::" . $module;
    }

    return if $self->emitters->{$module};
    die "Invalid module name: $module" unless $module =~ /^\w+(::\w+)*\z/;

    eval "require $module";
    die "Can't load emitter module $module: $@" if $@;

    my $obj = $module->new(main => $self);
    $self->emitters->{$module} = $obj;

    #$log->trace("<- register_emitter($module)");
}

=head2 register_plugin($module)

Load plugin module. $module will be prefixed by "Sah::Plugin::" (unless it's
prefixed by "^").

Example:

 $sah->register_plugin("Foo");  # loads Sah::Plugin::Foo
 $sah->register_plugin("^Bar"); # loads Bar

=cut

sub register_plugin {
    my ($self, $module) = @_;

    $log->trace("-> register_plugin($module)");

    if ($module =~ /^\^(.+)/) {
        $module = $1;
    } else {
        $module = "Sah::Emitter::" . $module;
    }
    # why would we want to limit one plugin instance per class?
    #return if grep { ref($_) eq $module } @{ $self->plugins };
    die "Invalid plugin module name: $module" unless $module =~ /^\w+(::\w+)*\z/;

    eval "require $module";
    die "Can't load plugin module $module: $@" if $@;

    my $obj = $module->new(main => $self);
    push @{ $self->plugins }, $obj;

    #$log->trace("<- register_plugin($module)");
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
            return $res if $res != -1;
        }
    }
    -1;
}

sub _register_schema_as_type {
    my ($self, $name, $schema) = @_;
    # XXX? normalize schema?
}

=head2 register_type($module) OR register_type($name => $schema)

Load type into list of known type roles and type names. $module will be prefixed
by "Sah::Type::" (unless it's prefixed by "^").

Example:

 $sah->register_type('Int');  # loads Sah::Type::Int
 $sah->register_type('^Bar'); # loads Bar

Will be called automatically by the constructor for all core types.

Can also be used to register a new type based on a schema.

=cut

sub register_type {
    my ($self, @args) = @_;

    if (@args == 1) {
        my $module = $args[0];
        $log->trace("-> register_type($module)");

        if ($module =~ /^\^(.+)/) {
            $module = $1;
        } else {
            $module = "Sah::Type::" . $module;
        }

        return if grep {$module eq $_} @{ $self->type_roles };
        die "Invalid type role name: $module" unless $module =~ /^\w+(::\w+)*\z/;

        eval "require $module";
        die "Can't load type role module $module: $@" if $@;
        no strict 'refs';
        my $m = $module . "::type_names";
        $m = $$m;
        die "Type role module $module does not define \$type_names" unless $m;

        push @{ $self->type_roles }, $module;
        for (ref($m) eq 'ARRAY' ? @$m : $m) {
            die "Module $module redefines type $_ (first defined by ".
                $self->type_names->{$_} . ")" if $self->type_names->{$_};
            $self->type_names->{$_} = $module;
        }
    } elsif (@args == 2) {
        $self->_register_schema_as_type(@args);
    } else {
        die "Usage: register_type(\$module) or ".
            "register_type(\$type_name => \$schema);";
    }

    #$log->trace("<- register_type($module)");
}

=head2 register_func($module)

Add function set module to list of function set modules to load by emitters.
"Sah::Func::" prefix will be added (unless module is prefixed by "^").

Example:

 $sah->register_func('Foo');  # registers Sah::Func::Foo
 $sah->register_func('^Bar'); # registers Bar

Will be called automatically in the constructor for the core function set.

=cut

sub register_func {
    my ($self, $module) = @_;

    $log->trace("-> register_func($module)");

    if ($module =~ /^\^(.+)/) {
        $module = $1;
    } else {
        $module = "Sah::Func::" . $module;
    }
    die "Invalid func module name: $module" unless $module =~ /^\w+(::\w+)*\z/;

    eval "require $module";
    die "Can't load function module role $module: $@" if $@;

    push @{ $self->func_roles }, $module;

    #$log->trace("<- register_func($module)");
}

=head2 register_lang($module_prefix)

Add language module prefix to list of language module prefixes to search by the
translation system. "Sah::Lang::" prefix will be added to the name (unless the
name is prefixed by "^").

Example:

 $sah->register_lang('Foo');  # registers Sah::Lang::Foo
 $sah->register_lang('^Bar'); # registers Bar

Later when a translation for a language (e.g. 'id') is needed, Sah::Lang::Foo::id
and Bar::id will also be searched. By default, only Sah::Lang::$lang_code will be
searched.

=cut

sub register_lang {
    my ($self, $prefix) = @_;

    $log->trace("-> register_lang($prefix)");

    if ($prefix =~ /^\^(.+)/) {
        $prefix = $1;
    } else {
        $prefix = "Sah::Lang::" . $prefix;
    }
    die "Invalid language module prefix: $prefix"
        unless $prefix =~ /^(|\w+(::\w+)*)\z/;
    push @{ $self->lang_module_prefixes }, $prefix;

    #$log->trace("<- register_lang($prefix)");
}

=head2 register_schema($module)

Register a schema set module. "Sah::Schema::" will be added to the name, unless
the module name is prefixed by "^".

Example:

 $sah->register_schema('Foo');  # register Sah::Schema::Foo
 $sah->register_schema('^Bar'); # register Bar

=cut

sub register_schema {
    my ($self, $module) = @_;

    if ($module =~ /^\^(.+)/) {
        $module = $1;
    } else {
        $module = "Sah::Type::" . $module;
    }

    die "Invalid schema module: $module" unless $module =~ /^\w+(::\w+)*\z/;

    eval "require $module";
    die "Can't load type role module $module: $@" if $@;
    no strict 'refs';
    my $s = $module . "::schemas";
    $s = $$s;
    die "Module $module does not define \$schemas" unless $s;
}

=head2 parse_string_shortcuts($str)

Parse string form shortcut notations, like "int*", "str[]", etc and return either
string $str unchanged if there is no shortcuts found, or array form, or undef if
there is an error.

Example: parse_string_shortcuts("int*") -> [int => {required=>1}]

=cut

=head2 normalize_schema($schema)

Normalize a schema into the hash form ({type=>..., clause_sets=>..., def=>...) as
well as do some sanity checks on it. Returns the normalized schema if succeeds,
or an error message string if fails.

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
    $self->func_names->{$name} ? 1:0;
}

=head2 emit($schema, $emitter_name, [$config])

Send schema to a specified emitter. Will try to load emitter first if not already
loaded.

=cut

sub emit {
    my ($self, $schema, $emitter_name, $config) = @_;
    $self->register_emitter($emitter_name) unless $self->emitters->{$emitter_name};
    my $e = $self->emitters->{$emitter_name};
    my $saved_config = $e->config;
    $e->config($config) if $config;
    my $res = $self->emitters->{$emitter_name}->emit($schema);
    $e->config($saved_config);
    $res;
}

=head2 perl($schema[, $config])

Convert schema to Perl code. The resulting Perl code can validate data against
said schema and can run standalone without Sah. This is equivalent to
calling:

 $sah->emit($schema, 'Perl', $config);

If you want to get the compiled code (as a coderef) directly, use C<compile>.

For more details, see L<Sah::Emitter::Perl>.

=cut

sub perl {
    my ($self, $schema, $config) = @_;
    return $self->emitters->{Perl} unless $schema;
    $self->emit($schema, 'Perl', $config);
}

=head2 human($schema, $config]])

Convert schema to human-friendly text description. This is equivalent to calling:

 $sah->emit($schema, 'Perl', $config);

For more details, see L<Sah::Emitter::Human>.

=cut

sub human {
    my ($self, $schema, $config) = @_;
    return $self->emitters->{Human} unless $schema;
    $self->emit($schema, 'Human', $config);
}

=head2 js($schema, $config]])

Convert schema to JavaScript code. Requires L<Sah::Emitter::JS>. This is
equivalent to calling:

 $sah->emit($schema, 'JS', $config);

For more details, see L<Sah::Emitter::JS>.

=cut

sub js {
    my ($self, $schema, $config) = @_;
    return $self->emitters->{js} unless $schema;
    $self->emit($schema, 'JS', $config);
}

=head2 compile($schema, $config]])

Compile the schema into Perl code and return a 2-element list: ($coderef,
$subname). $coderef is the resulting subroutine and $subname is the subroutine
name in the compilation namespace.

Dies if code can't be generated, or an error occured when compiling the code.

If you want to get the Perl code in a string, use C<perl>.

The Perl sub accepts data and will return {success=>0 or 1, errors=>[...],
warnings=>[...]} (but also see B<report_all_errors> config). The 'success' key
will be set to 1 if the data validates, otherwise 'errors' and 'warnings' will be
filled with the details.

=cut

sub compile {
    my ($self, $schema, $config) = @_;
    my $e = $self->emitters->{Perl};

    $schema = $self->normalize_schema($schema);
    die "Can't normalize schema: $schema" unless ref($schema);

    my $saved_config = $e->config;
    $e->config($config) if $config;
    my $perl = $e->emit($schema);
    eval $perl;
    my $eval_error = $@;
    if ($eval_error) {
        print STDERR $perl, $eval_error if $log->is_debug;
        die "Can't compile Perl code: $eval_error";
    }
    $e->config($saved_config);

    my $csubname = $e->subname($schema);
    my $csubfullname = ($e->config->namespace ? $e->config->namespace . '::' : '').
        $csubname;
    if (wantarray) {
        return (\&$csubfullname, $csubname);
    } else {
        return \&$csubfullname;
    }
}

=head1 FAQ

=head3 Why might one choose Sah over other data validation/schema/type system on CPAN?

B<Validation speed>. Many other modules interpret schema on the fly instead of
compiling it directly to Perl code. While this is sufficiently speedy for many
cases, it can be one order of magnitude or more slower than compiled schema.

B<Portability>. Sah supports functions and expressions using a minilanguage which
will be converted into target language, instead of letting user specify direct
Perl code in their schema. While this is a bit more cumbersome, it makes schema
easier to port/compile to languages other than Perl (e.g. JavaScript, to generate
client-side web form validation code). The type hierarchy is also more
language-neutral instead of being more Perl-specific like the Moose type system.

B<Syntax>. While syntax is largely a matter of taste, I have tried to make Sah
schema easy and convenient to write by providing alternate forms, shortcuts, and
aliases for type/clause names.

=head3 Why the name?

Sah is an Indonesian word, meaning 'valid'. It's short.

The previous incarnation of this module uses the name Data::Schema. Since then,
there are many added features, a few removed ones, some syntax and terminology
changes, thus the new name.


=head1 MODULE ORGANIZATION

Sah::Type::* roles specifies a type, e.g. Sah::Type::Bool specifies the boolean
type.

Sah::Func::* roles specifies bundles of functions, e.g. Sah::Func::Core specifies
the core/standard functions.

Sah::Emitter::$LANG:: is for emitters. Each emitter might further contain
::Type::* and ::Func::* to implement appropriate functionalities, e.g.
Sah::Emitter::Perl::Type::Bool is the emitter for boolean.

Sah::Lang:: namespace is reserved for modules that contain translations. The last
part of the qualified name is the 2-letter language code.

Sah::Schema:: namespace is reserved for modules that contain bundles of schemas.
For example, L<Sah::Schema::CPANMeta> contains the schema to validate CPAN
META.yml. L<Sah::Schema::Schema> contains the schema for Sah schema itself.

=head1 SEE ALSO

B<Moose> has a type system. B<MooseX::Params::Validate>, among others, can
validate method parameters based on this.

Some other data validation and data schema modules on CPAN:
L<Data::FormValidator>, L<Params::Validate>, L<Data::Rx>, L<Kwalify>,
L<Data::Verifier>, L<Data::Validator>, L<JSON::Schema>.

=cut

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
