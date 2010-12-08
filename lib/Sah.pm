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
use Data::Dump::OneLine;
use Data::ModeMerge;
use Digest::MD5 qw(md5_hex);
use Log::Any qw($log);
use URI::Escape;


=head1 ATTRIBUTES

=cut

has merger => (
    is      => 'ro',
    default => Data::ModeMerge->new(config=>{recurse_array=>1}),
);

has emitters => (
    is      => 'rw',
    default => sub { {} },
);

has plugins => (
    is      => 'rw',
    default => sub { [] },
);

my $default_type_roles = qw(
                               All Array Bool CIStr DateTime Either
                               Float Hash Int Object Str
                       );

has type_roles => (
    is      => 'rw',
    default => sub { [] },
);

has type_names => (
    is       => 'rw',
    default => sub { {} },
);

has lang_modules => (
    is      => 'rw',
    default => sub { [] }
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

sub _dump {
    my $self = shift;
    return Data::Dump::OneLine::dump_one_line(@_);
}

=head2 merge_clause_sets($clause_sets)

Merge several clause sets if there are sets that can be merged (i.e. contains
merge prefix in its keys).

=cut

sub merge_clause_sets {
    my ($self, $clause_sets) = @_;
    my @merged;
    my $res = {error=>''};

    my $mm = $self->merger;
    my @c;
    for (@$clause_sets) {
        push @cs, {cs=>$_, has_prefix=>$mm->check_prefix_on_hash($_)};
    }
    for (reverse @cs) {
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
            ($c->{last_with_prefix} || $a[$i-1]{last_with_prefix}) ? 0 : 1);
        my $mres = $mm->merge($merged[-1], $c->{cs});
        if (!$mres->{success}) {
            $res->{error} = $mres->{error};
            last;
        }
        $merged[-1] = $mres->{result};
    }
    $res->{result} = \@merged unless $res->{error};
    $res->{success} = !$res->{error};
    $res;
}

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
    $self->emitters->{$name} = $obj;

    $log->trace("<- register_emitter($module)");
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
    return if grep { ref($_) eq $module } @{ $self->plugins };
    die "Invalid plugin module name: $module" unless $module =~ /^\w+(::\w+)*\z/;

    eval "require $module";
    die "Can't load plugin module $module: $@" if $@;

    my $obj = $module->new(main => $self);
    push @{ $self->plugins }, $obj;

    $log->trace("<- register_plugin($module)");
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

=head2 register_type($module)

Load type into list of known type roles and type names. $module will be prefixed
by "Sah::Type::" (unless it's prefixed by "^").

Example:

 $sah->register_type('Int');  # loads Sah::Type::Int
 $sah->register_type('^Bar'); # loads Bar

Will be called automatically by the constructor for all core types.

=cut

sub register_type {
    my ($self, $module) = @_;

    $log->trace("-> register_type($module)");

    if ($module =~ /^\^(.+)/) {
        $module = $1;
    } else {
        $module = "Sah::Type::" . $module;
    }

    return if grep {$name eq $_} @{ $self->type_roles };
    $module = "Sah::Spec::v10::Type::" . $module;
    die "Invalid type role name: $module" unless $module =~ /^\w+(::\w+)*\z/;

    eval "require $module";
    die "Can't load type role $module: $@" if $@;
    no strict 'refs';
    my $m = $module . "::typenames";
    $m = $$m;
    die "Type module $module does not contain types" unless $m;

    push @{ $self->type_roles }, $name;
    for (ref($m) eq 'ARRAY' ? @$m : $m) {
        die "Module $module redefined type $_ (first defined by ".
            $self->type_names->{$_} . ")" if $self->type_names->{$_};
        $self->type_names->{$_} = $name;
    }
}

=head2 register_func($module)

Add function module to list of function modules to load by emitters.

Example:

 $sah->register_func('Foo');

Later when emitters are loaded, each will try to load
Sah::Emitter::$EMITTER::Func::Foo.

Will be called automatically by the constructor for all default/builtin function
modules, or if you request when importing Sah:

 use Sah -funcs => ['Foo'];

=cut

sub register_func {
    my ($self, $module) = @_;

    $log->trace("register_func($module)");

    $module =~ s/^Sah::Spec::v10::Func:://;
    my $name = $module;
    do { warn "Function module $name already loaded"; return }
        if grep {$name eq $_} @{ $self->func_roles };
    $module = "Sah::Spec::v10::Func::" . $module;
    die "Invalid function module name: $module" unless $module =~ /^\w+(::\w+)*\z/;
    push @{ $self->func_roles }, $name;

    eval "require $module";
    die "Can't load function module role $module: $@" if $@;
    use Any::Moose '::Util';
    my $meta = Mouse::Util::get_metaclass_by_name($module); # XXX how to not explicitly say Mouse here?
    for ($meta->get_required_method_list) {
        s/^func_// or next;
        die "Function module $module redefined func $_ (first defined by ".
            $self->func_names->{$_} . ")" if $self->func_names->{$_};
        $self->func_names->{$_} = $name;
    }
}

=head2 register_lang($module)

Add language module to list of language modules to load by translation system.

Example:

 $sah->register_lang('Foo');

Later when a translation for a language (e.g. 'id') is needed,
Sah::Lang::Foo::id will also be searched.

Will be called automatically by the constructor for all default/builtin language
modules, or if you request when importing Sah:

 use Sah -langs => ['Foo'];

=cut

sub register_lang {
    my ($self, $module) = @_;

    $log->trace("register_lang($module)");

    $module =~ s/^Sah::Lang:://;
    my $name = $module;
    do { warn "Language module $name already added"; return }
        if grep {$name eq $_} @{ $self->lang_modules };
    die "Invalid language module name: $module" unless $module =~ /^(|\w+(::\w+)*)\z/;
    push @{ $self->lang_modules }, $module;
}

=head2 register_schema($module) OR register_schema($schema, @names)

Register a schema module (or schema).

Example:

 $sah->register_schema('Foo');

Will be called automatically by the constructor for all default/builtin schema
modules, or if you request when importing Sah:

 use Sah -schemas => ['Foo'];

Can also be used to register single schema:

 $sah->register_schema([str=>{match=>qr/.+\@.+/}], 'email');

This will register schema with the name 'email'.

=cut

sub register_schema {
    my ($self, @arg) = @_;
    if (@arg > 1) {
        my $schema = shift @arg;
        $schema = $self->normalize_schema($schema);
        die "Can't normalize schema: $schema" unless ref($schema);
        my @names = @arg;
            $log->tracef("register_schema(%s, %s)", $schema, join(", ", @names));
        for (@names) {
            die "Type `$_` already defined" if $self->type_names->{$_};
            $self->type_names->{$_} = $schema;
        }
    } else {
        my $module = $arg[0];
        $log->trace("register_schema($module)");
        $module =~ s/^Sah::Schema:://;
        $module = "Sah::Schema::" . $module;
        die "Invalid schema module name: $module" unless $module =~ /^\w+(::\w+)*\z/;
        eval "require $module";
        die "Can't load schema module $module: $@" if $@;
        my $s = $module->schemas;
        for (keys %$s) {
            die "Schema `$_` redefined by module: $module"
                if $self->type_names->{$_};
            my $nschema = $self->normalize_schema($s->{$_});
            die "Can't normalize schema `$_`: $nschema" unless ref($nschema);
            $self->type_names->{$_} = $nschema;
        }
    }
}

# _parse_shortcuts($str)
#
# Parse 1st form shortcut notations, like "int*", "str[]", etc and return either
# the first form ($str unchanged) if there is no shortcuts found, or the second
# form (2-element arrayref), or undef if there is an error.

my $ps_loaded;
sub _parse_shortcuts {
    my ($self, $str) = @_;
    return $str if $str =~ /^\w+$/;

    require Sah::ParseShortcut unless $ps_loaded;
    $ps_loaded++;
    Sah::ParseShortcut::__parse_shortcuts($str);
}

=head2 normalize_schema($schema)

Normalize a schema into the third form (hash form) ({type=>..., attr_hashes=>...,
def=>...) as well as do some sanity checks on it. Returns the normalized schema
if succeeds, or an error message string if fails.

=cut

sub normalize_schema {
    my ($self, $schema) = @_;

    if (!defined($schema)) {

        return "schema is missing";

    } elsif (!ref($schema)) {

        my $s = $self->_parse_shortcuts($schema);
        if (!defined($s)) {
            return "can't understand type name / parse shortcuts in string `$schema`";
        } elsif (!ref($s)) {
            return { type=>$s, attr_hashes=>[], def=>{} };
        } else {
            return { type=>$s->[0], attr_hashes=>[$s->[1]], def=>{} };
        }

    } elsif (ref($schema) eq 'ARRAY') {

        if (!defined($schema->[0])) {
            return "array form needs at least 1 element for type";
        } elsif (ref($schema->[0])) {
            return "array form's first element must be a string";
        }
        my $s = $self->_parse_shortcuts($schema->[0]);
        my $t;
        my $ah0;
        if (!defined($s)) {
            return "can't understand type name / parse shortcuts in first element `$schema->[0]`";
        } elsif (!ref($s)) {
            $t = $s;
            $ah0 = {};
        } else {
            $t = $s->[0];
            $ah0 = $s->[1];
        }
        my @attr_hashes;
        if (@$schema > 1) {
            for (1..@$schema-1) {
                if (ref($schema->[$_]) ne 'HASH') {
                    return "array form element [$_] (attrhash) must be a hashref";
                }
                my $ah = $_ == 1 ? {%$ah0, %{$schema->[1]}} : $schema->[$_];
                push @attr_hashes, $ah;
            }
        } else {
            push @attr_hashes, $ah0 if keys(%$ah0);
        }
        return { type=>$t, attr_hashes=>\@attr_hashes, def=>{} };

    } elsif (ref($schema) eq 'HASH') {

        if (!defined($schema->{type})) {
            return "hash form must have 'type' key";
        }
        my $s = $self->_parse_shortcuts($schema->{type});
        my $t;
        my $ah0;
        if (!defined($s)) {
            return "can't understand type name / parse shortcuts in 'type' value `$schema->[0]`";
        } elsif (!ref($s)) {
            $t = $s;
        } else {
            $t = $s->[0];
            $ah0 = $s->[1];
        }
        my @attr_hashes;
        $a = $schema->{attr_hashes};
        if (defined($a)) {
            if (ref($a) ne 'ARRAY') {
                return "hash form 'attr_hashes' key must be an arrayref";
            }
            for (0..@$a-1) {
                if (ref($a->[$_]) ne 'HASH') {
                    return "hash form 'attr_hashes'[$_] must be a hashref";
                }
                push @attr_hashes, $a->[$_];
            }
        }
        if ($ah0) {
            if (@attr_hashes) {
                $attr_hashes[0] = {%$ah0, %{$attr_hashes[0]}};
            } else {
                push @attr_hashes, $ah0;
            }
        }
        $a = $schema->{def};
        if (defined($a)) {
            if (ref($a) ne 'HASH') {
                return "hash form 'def' key must be a hashref";
            }
        }
        my $def = $a // {};
        for (keys %$schema) {
            return "hash form has unknown key `$_'" unless /^(type|attr_hashes|def)$/;
        }
        return { type=>$t, attr_hashes=>\@attr_hashes, def=>$def };

    }

    return "schema must be a str, arrayref, or hashref";
}

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

=head2 validate($data, $schema)

B<DEPRECATED!> Use compile() and validate using the generated Perl code instead.

Validate a data structure. $schema must be given unless you already give the
schema via the B<schema> attribute.

This is just a shortcut for compile() + calling the generated code to validate
data. Plus with some caching to avoid repetitive compilation when $schema has
been previously mentioned.

=cut

sub validate {
    my ($self, $data, $schema) = @_;
    state $compiled_schemas = {};

    my $key = join("-",
                   md5_hex($self->_dump($schema)),
                   md5_hex($self->_dump($self->config))
               );
    unless ($compiled_schemas->{$key}) {
        my ($sub, $name) = $self->compile($schema);
        $compiled_schemas->{$key} = $sub;
    }
    $compiled_schemas->{$key}($data);
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
