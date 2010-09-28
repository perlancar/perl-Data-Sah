package Data::Schema;
# ABSTRACT: Schema language for data structures

=head1 SYNOPSIS

    use Data::Schema;
    my $ds = new Data::Schema;

    my $schema = ["hash", {
        keys => {
            name => "str",
            age  => ["int", {required=>1, min=>18}]
        }
    }];

    # validate data against schema

    my $sub = $ds->compile($schema);
    print "success" if $sub->({name=>"Lucy", age=>18})->{success}; # success
    print "success" if $sub->({name=>"Lucy"         })->{success}; # fail: missing age
    print "success" if $sub->({name=>"Lucy", age=>16})->{success}; # fail: underage

    # convert schema to Perl code

    $perl = $ds->perl($schema);

    # convert schema to JavaScript code (requires L<Data::Schema::Emmitter::JS>)

    $js = $ds->js($schema);

    # generate text description from schema

    print $ds->human('int[]'); # 'Array. Elements must be integer.'

    # ditto, but in Indonesian

    print $ds->human('int[]', {lang=>'id'}); # 'Larik. Elemen harus bilangan bulat.'

    # ditto, but in HTML. Suitable for generating specification document of
    # complex schema.

    $schema = ['str*' => {
        ".description" => "Password",
        len_between => [6, 15],
        "len_min:warn" => 8,
        match => qr/[a-z][0-9]|[0-9][a-z]/i,
        "match.errmsg.en" => "must contain at least one letter AND number",
        not_one_of => [qw/password passwd abc123 abcd1234/],
    }];
    print $ds->human($schema, {format=>'html'});

    # the above will output something that renders like:

    Password. Text. Must be provided. Length must be between 6 and 15. Length
    should be at least 8. Must contain at least one letter AND number. Must not
    be one of:

     o 'password'
     o 'passwd'
     o 'abc123'
     o 'abcd1234'

    # for more on getting started, see Data::Schema::Manual::Tutorial



    # some schema examples

    # -- array
    "array"

    # -- array of ints
    [array => {of=>"int"}]

    # -- array of ints (using 1st form shortcut notation)
    "int[]"

    # -- array of positive, even ints
    [array => {of=>[int => {min=>0, divisible_by=>2}]}]

    # -- 3x3x3 "multi-dim" arrays
    [array => {len=>3, of=>
        [array => {len=>3, of=>
            [array => {len=>3}]}]}]

    # -- HTTP headers, each header can be a string or array of strings
    [hash => {
        required => 1,
        keys_match => '^\w+(-w+)*$',
        values_of => [either => {of=>[
            "str",
            [array=>{of=>"str", minlen=>1}],
        ]}],
    }]

    # for more examples, see Data::Schema::Manual::Cookbook

=head1 DESCRIPTION

Data::Schema (DS) is a schema language to validate data structures.

Features/highlights:

=over 4

=item * Expressed as data structure

The use of data structures as schema simplifies schema manipulation and
conversion to other languages. There are some shortcut syntax but they can all be
normalized to the nested data structure.

Some examples:

 'int'                               -> integer
 [int => {}]                         -> same thing

 [int => {required=>1}]              -> integer, required
 'int*'                              -> same thing

 [ int   => {required=>1,
             min=>1, max=>10}]       -> integer, required, min 1, max 10
 ['int*' => {min=>1, max=>10}]       -> same thing

 ['array' => {of=>'int'}]            -> array of integers
 'int[]'                             -> same thing

 [ array  => {of=>'int', minlen=>2}] -> array of at least 2 integers

 [ array  => {of=>[int => {min=>0}],
              minlen=>2}]            -> array of at least 2 positive
                                        integers

 [ array => {of=>
    [ array => {of=>'str*'} ]}]      -> array of array of strings
 [ array => {of=>'(str*)[]'} ]       -> same thing
 '((str*)[])[]'                      -> same thing

See L<Data::Schema::Manual::Schema> for full syntax. There are just a few syntax
rules and the concept is simple.

=item * Conversion into Perl, JavaScript (and other languages)

You can convert DS schema into Perl, JavaScript, and other (when an emitter for
that language exists). This means you only write validation code once and use it
anywhere, saving you from tedious coding of data validation code multiple times
in each target language.

The generated Perl/JavaScript/etc code can run without this module.

=item * Conversion into human description text

DS schema can also be converted into human text, technically it's just another
emitter. This can be used to generate specification document, error messages, etc
directly from the schema. This saves you from having to write for many common
error messages (but you can supply your own when needed).

The human text is translatable and can be output in various forms (as a single
sentence, single paragraph, or multiple paragraphs) and formats (text, HTML, raw
markup).

=item * Ability to express pretty complex schema

DS supports common types and a quite rich set of type attributes for each type.
You can flexibly specify valid/invalid ranges of values, dependencies, conflict
rules, etc. There are also filters/functions and expressions.

DS can handle nested (deep) as well as recursive (circular) data and schemas.

You can add your own types and functions if what you need is not supported out of
the box.

=item * Emphasis on reusability

You can define schemas in terms of other schemas. Example:

 # array of unique gmail addresses
 [array => {unique => 1, of => [email => {match => qr/gmail\.com$/}]}]

In the above example, the schema is based on 'email'. Email can be a type or just
another schema:

  # definition of email
  [str => {match => ".+\@.+"}]

You can also define in terms of other schemas with some modification.

 # schema: even
 [int => {divisible_by=>2}]

 # schema: pos_even
 [even => {min=>0}]

In the above example, 'pos_even' is defined from 'even' with an additional
attribute (min=>0). As a matter of fact you can also override and B<remove>
restrictions from your base schema, for even more flexibility.

 # schema: pos_even_or_odd
 [pos_even => {"!divisible_by"=>2}] # remove the divisible_by attribute

The above example makes 'even_or_odd' effectively equivalent to positive integer.

See L<Data::Schema::Manual::Schema> for more about attribute merging.

=back

Applications for DS: validating subroutine arguments, configuration, forms,
command line arguments, etc.

To get started, see L<Data::Schema::Manual::Tutorial>.

=cut

use feature 'state';

use Any::Moose;
use Data::Dumper;
use Data::ModeMerge;
use Data::Schema::Config;
use Digest::MD5 qw(md5_hex);
use Log::Any qw($log);
use URI::Escape;

# importer may specify additional modules to load. key = importer
# package. value = { types => [...], langs => [...], funcs => [...],
# plugins => [...], schemas => [...] }
my %Import_Adds;

=head1 IMPORTING

When importing this module, you can pass a list of arguments.

 use Data::Schema -plugins => ["Foo"], -types => ["Bar"], ...;
 my $ds = Data::Schema->new;

See import() for more details.

=head1 FUNCTIONS

=head2 ds_validate($data, $schema)

B<DEPRECATED!> Use the OO interface and compile() instead.

Non-OO wrapper for validate(). Exported by default. See C<validate()> method.

=cut

sub ds_validate {
    my ($data, $schema) = @_;
    my $ds = __PACKAGE__->new(schema => $schema);
    $ds->validate($data);
}

=head1 ATTRIBUTES

Normally, aside from B<config>, you wouldn't need to use any of these.

=cut

=head2 merger

The Data::ModeMerge instance.

=cut

has merger => (is => 'rw');

=head2 config

Configuration object. See L<Data::Schema::Config>.

=cut

has config => (is => 'rw');

=head2 emitters

List of emitter instances.

=cut

has emitters => (is => 'rw', default => sub { {} });

my $Default_Emitters = [qw//];

=head2 plugins

List of plugin instances.

=cut

has plugins => (is => 'rw', default => sub { [] });

my $Default_Plugins = [qw//];

=head2 type_roles

All known type roles (without the C<Data::Schema::Type::> prefix. When loading an
emitter, the emitter will try to load all its type handlers based on this list,
e.g. when B<type_roles> is ['Int', 'Foo'] then emitter Perl will try to load
'Data::Schema::Emitter::Perl::Type::Int' and
'Data::Schema::Emitter::Perl::Type::Foo'.

Default type roles are All, Array, Bool, CIStr, DateTime, Either, Float, Hash,
Int, Object, Str.

=cut

has type_roles => (is => 'rw', default => sub { [] });

my $Default_Type_Roles = [qw/All Array Bool CIStr DateTime Either Float Hash Int
                             Object Str/];

=head2 type_names

All known type names (as well as schema names). This will be populated by loading
all type roles and extracting type names from each, as well as by
register_schema().

B<type_names> is a hash. Keys are type names. If type is handled by a type
module, value will be string containing the module name. If type is a schema it
will be a hashref containing the normalized schema.

=cut

has type_names => (is => 'rw', default => sub { {} });

=head2 lang_modules

List of language module prefix to search (without 'Data::Schema::Lang'). Default
is ['']. When searching for translation for a language (e.g. 'id'), all prefixes
on this list will be searched. If B<lang_modules> is e.g. ['', 'Foo'] then
'Data::Schema::Lang::id' and 'Data::Schema::Lang::Foo::id' will be tried when
searching for an Indonesian translation.

=cut

has lang_modules => (is => 'rw', default => sub { [] } );

my $Default_Lang_Modules = [''];

=head2 func_modules

All known function modules (without the 'Data::Schema::Func' prefix). When
loading an emitter, the emitter will try to load all its function emitters based
on this list.

Default function module is ['Std'].

=cut

has func_modules => (is => 'rw', default => sub { [] });

my $Default_Func_Modules = ['Std'];

=head2 func_names

All known function names. This will be populated by loading all function modules
and extracting function names from each.

=cut

has func_names => (is => 'rw', default => sub { {} });

my $Default_Schema_Modules = ['Std'];


=head1 METHODS

For typical usage, you only need B<compile()> to generate Perl sub and validate
your data against it. And B<js()>, B<php()> if you want to generate JavaScript
and PHP code.

=cut

sub _dump {
    my $self = shift;
    Data::Dumper->new([@_])->Indent(0)->Terse(1)->Sortkeys(1)->Purity(0)->Dump();
}

my $Caller;
sub BUILD {
    my ($self, $args) = @_;

    $self->merger(Data::ModeMerge->new(config=>{recurse_array=>1}));

    # config
    if ($self->config) {
        # some sanity checks
        my $is_hashref = ref($self->config) eq 'HASH';
        die "config must be a hashref or a Data::Schema::Config" unless
            $is_hashref || UNIVERSAL::isa($self->config, "Data::Schema::Config");
        $self->config(Data::Schema::Config->new(%{ $self->config })) if $is_hashref;
        # common mistake
        die "config->schema_search_path must be an arrayref"
            unless ref($self->config->schema_search_path) eq 'ARRAY';
    } else {
        $self->config(Data::Schema::Config->new);
    }

    # additional modules
    $self->register_plugin($_)
        for (@$Default_Plugins,
             ($Caller && $Import_Adds{$Caller}{plugins} ?
                 @{ $Import_Adds{$Caller}{plugins} } : ()));
    $self->register_type($_)
        for (@$Default_Type_Roles,
             ($Caller && $Import_Adds{$Caller}{types} ?
                 @{ $Import_Adds{$Caller}{types} } : ()));
    $self->register_func($_)
        for (@$Default_Func_Modules,
             ($Caller && $Import_Adds{$Caller}{funcs} ?
                 @{ $Import_Adds{$Caller}{funcs} } : ()));
    $self->register_schema($_)
        for (@$Default_Schema_Modules,
             ($Caller && $Import_Adds{$Caller}{schemas} ?
                 @{ $Import_Adds{$Caller}{schemas} } : ()));
    $self->register_lang($_)
        for (@$Default_Lang_Modules,
             ($Caller && $Import_Adds{$Caller}{langs} ?
                 @{ $Import_Adds{$Caller}{langs} } : ()));
    # must be done aftere func & type
    $self->register_emitter($_)
        for (@$Default_Emitters,
             ($Caller && $Import_Adds{$Caller}{emitters} ?
                 @{ $Import_Adds{$Caller}{emitters} } : ()));
}

# Merge several attribute hashes if there are hashes that can be merged (i.e.
# contains merge prefix in its keys). Used by DSE::Base.

sub _merge_attr_hashes {
    my ($self, $attr_hashes) = @_;
    my @merged;
    #my $did_merging;
    my $res = {error=>''};
    #print "#DEBUG: Entering merge_attr_hashes\n";

    #$self->merger(Data::ModeMerge->new(config=>{recurse_array=>1}));
    my $mm = $self->merger;
    #print "#DEBUG: merger = ".__dump($mm)."\n";

    #print "#DEBUG:   attr_hashes->[$_] = ".__dump($attr_hashes->[$_])."\n" for (0..@$attr_hashes-1);

    my @a;
    for (@$attr_hashes) {
        push @a, {ah=>$_, has_prefix=>$mm->check_prefix_on_hash($_)};
    }
    for (reverse @a) {
        if ($_->{has_prefix}) { $_->{last_with_prefix} = 1; last }
    }
    #print "#DEBUG:   a[$_] = ".__dump($a[$_])."\n" for (0..@a-1);

    my $i = -1;
    for (@a) {
        $i++;
        if (!$i || !$_->{has_prefix} && !$a[$i-1]{has_prefix}) {
            push @merged, $_->{ah};
            next;
        }
        $mm->config->readd_prefix(($_->{last_with_prefix} || $a[$i-1]{last_with_prefix}) ? 0 : 1);
        my $mres = $mm->merge($merged[-1], $_->{ah});
        if (!$mres->{success}) {
            $res->{error} = $mres->{error};
            last;
        }
        $merged[-1] = $mres->{result};
    }
    $res->{result} = \@merged unless $res->{error};
    $res->{success} = !$res->{error};

    #print "#DEBUG:   res->{error} = $res->{error}\n";
    #unless ($res->{error}) { print "#DEBUG:   res->{result}[$_] = ".__dump($merged[$_])."\n" for (0..@merged-1) }
    #print "#DEBUG: Leaving merge_attr_hashes\n";

    $res;
}

=head2 register_emitter($module)

Load emitter. $module will be prefixed by "Data::Schema::Emitter::".

Example:

 $ds->register_emitter('JS');

Will be called automatically for all the default emitters (Human and Perl), or by
emit() when an unloaded emitter is requested, or if you request it when importing
Data::Schema:

 use Data::Schema -emitters => ['JS'];

=cut

sub register_emitter {
    my ($self, $module) = @_;

    $log->trace("register_emitter($module)");

    $module =~ s/^Data::Schema::Emitter:://;
    my $name = $module;
    do { warn "Emitter $name already loaded"; return } if $self->emitters->{$name};

    $module = "Data::Schema::Emitter::" . $module;
    die "Invalid module name: $module" unless $module =~ /^\w+(::\w+)*\z/;

    eval "require $module";
    die "Can't load emitter class $module: $@" if $@;

    my $confmodule = $module . "::Config";
    eval "require $confmodule";
    die "Can't load emitter config class $confmodule: $@" if $@;

    my $obj = $module->new(main => $self, config => $confmodule->new);
    $self->emitters->{$name} = $obj;
}

=head2 register_plugin($module)

Load plugin module. $module will be prefixed by "Data::Schema::Plugin::".

Example:

 $ds->register_plugin("LoadSchema::YAMLFile");

Will be called automatically if you request plugins when importing Data::Schema:

 use Data::Schema -plugins => ["LoadSchema::YAMLFile"];

=cut

sub register_plugin {
    my ($self, $module) = @_;

    $log->trace("register_plugin($module)");

    $module =~ s/^Data::Schema::Plugin:://;
    $module = "Data::Schema::Plugin::" . $module;
    die "Invalid plugin module name: $module" unless $module =~ /^\w+(::\w+)*\z/;

    eval "require $module";
    die "Can't load plugin class $module: $@" if $@;

    my $obj = $module->new(main => $self);
    push @{ $self->plugins }, $obj;
}

sub _call_plugin_hook {
    my ($self, $name, @args) = @_;
    $name = "hook_$name" unless $name =~ /^hook_/;
    for my $p (@{ $self->plugins }) {
        if ($p->can($name)) {
            $log->tracef("Calling plugin: %s->%s(\@{ %s })", ref($p), $name, \@args);
	    my $res = $p->$name(@args);
            $log->tracef("Result from plugin: %d", $res);
            return $res if $res != -1;
        }
    }
    -1;
}

=head2 register_type($module)

Load type into list of known type roles and type names. $module will be prefixed
by "Data::Schema::Type::".

Example:

 $ds->register_type('Int');

Will be called automatically by the constructor for all default/builtin types, or
if you request when importing Data::Schema:

 use Data::Schema -types => ['Foo'];

=cut

sub register_type {
    my ($self, $module) = @_;

    $log->trace("register_type($module)");

    $module =~ s/^Data::Schema::Type:://;
    my $name = $module;
    do { warn "Type module $name already loaded"; return }
        if grep {$name eq $_} @{ $self->type_roles };
    $module = "Data::Schema::Type::" . $module;
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

 $ds->register_func('Foo');

Later when emitters are loaded, each will try to load
Data::Schema::Emitter::$EMITTER::Func::Foo.

Will be called automatically by the constructor for all default/builtin function
modules, or if you request when importing Data::Schema:

 use Data::Schema -funcs => ['Foo'];

=cut

sub register_func {
    my ($self, $module) = @_;

    $log->trace("register_func($module)");

    $module =~ s/^Data::Schema::Func:://;
    my $name = $module;
    do { warn "Function module $name already loaded"; return }
        if grep {$name eq $_} @{ $self->func_modules };
    $module = "Data::Schema::Func::" . $module;
    die "Invalid function module name: $module" unless $module =~ /^\w+(::\w+)*\z/;
    push @{ $self->func_modules }, $module;

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

 $ds->register_lang('Foo');

Later when a translation for a language (e.g. 'id') is needed,
Data::Schema::Lang::Foo::id will also be searched.

Will be called automatically by the constructor for all default/builtin language
modules, or if you request when importing Data::Schema:

 use Data::Schema -langs => ['Foo'];

=cut

sub register_lang {
    my ($self, $module) = @_;

    $log->trace("register_lang($module)");

    $module =~ s/^Data::Schema::Lang:://;
    my $name = $module;
    do { warn "Language module $name already added"; return }
        if grep {$name eq $_} @{ $self->lang_modules };
    die "Invalid language module name: $module" unless $module =~ /^(|\w+(::\w+)*)\z/;
    push @{ $self->lang_modules }, $module;
}

=head2 register_schema($module) OR register_schema($schema, @names)

Register a schema module (or schema).

Example:

 $ds->register_schema('Foo');

Will be called automatically by the constructor for all default/builtin schema
modules, or if you request when importing Data::Schema:

 use Data::Schema -schemas => ['Foo'];

Can also be used to register single schema:

 $ds->register_schema([str=>{match=>qr/.+\@.+/}], 'email');

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
        $module =~ s/^Data::Schema::Schema:://;
        $module = "Data::Schema::Schema::" . $module;
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

    require Data::Schema::ParseShortcut unless $ps_loaded;
    $ps_loaded++;
    Data::Schema::ParseShortcut::__parse_shortcuts($str);
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
        my $a = $schema->{attrs};
        if (defined($a)) {
            if (ref($a) ne 'HASH') {
                return "hash form 'attrs' key must be a hashref";
            }
            push @attr_hashes, $a;
        }
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
            return "hash form has unknown key `$_'" unless /^(type|attrs|attr_hashes|def)$/;
        }
        return { type=>$t, attr_hashes=>\@attr_hashes, def=>$def };

    }

    return "schema must be a str, arrayref, or hashref";
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
said schema and can run standalone without Data::Schema. This is equivalent to
calling:

 $ds->emit($schema, 'Perl', $config);

If you want to get the compiled code (as a coderef) directly, use C<compile>.

For more details, see L<Data::Schema::Emitter::Perl>.

=cut

sub perl {
    my ($self, $schema, $config) = @_;
    $self->emit($schema, 'Perl', $config);
}

=head2 human($schema, $config]])

Convert schema to human-friendly text description. This is equivalent to calling:

 $ds->emit($schema, 'Perl', $config);

For more details, see L<Data::Schema::Emitter::Human>.

=cut

sub human {
    my ($self, $schema, $config) = @_;
    $self->emit($schema, 'Human', $config);
}

=head2 js($schema, $config]])

Convert schema to JavaScript code. Requires L<Data::Schema::Emitter::JS>. This is
equivalent to calling:

 $ds->emit($schema, 'JS', $config);

For more details, see L<Data::Schema::Emitter::JS>.

=cut

sub js {
    my ($self, $schema, $config) = @_;
    $self->emit($schema, 'JS', $config);
}

=head2 compile($schema, $config]])

Compile the schema into Perl code and return a 2-element list: ($coderef,
$subname). $coderef is the resulting subroutine and $subname is the subroutine
name in the compilation namespace.

Dies if code can't be generated, or an error occured when compiling the code.

If you want to get the Perl code in a string, use C<perl>.

The Perl sub accepts data and will return {success=>0 or 1, errors=>[...],
warnings=>[...]}. The 'success' key will be set to 1 if the data validates,
otherwise 'errors' and 'warnings' will be filled with the details.

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

    my $csubname = $e->_schema2csubname($schema);
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

    my $saved_schema = $self->schema;
    $schema //= $self->schema;

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

=head2 import(@args)

Argument can be B<ds_validate>, or -option => VALUE.

Options:

=over 4

=item -plugins => ["Foo", ...]

This is a shortcut for:

 $ds->register_plugin('Foo');
 ...

=item -types => ["Foo", ...]

A shortcut for:

 $ds->register_type('Foo');
 ...

=item -funcs => ["Foo", ...]

A shortcut for:

 $ds->register_func('Foo');
 ...

=item -schemas => ["Foo", ...]

A shortcut for:

 $ds->register_schema('Foo');
 ...

=item -langs => ["Foo", ...]

A shortcut for:

 $ds->register_lang('Foo');
 ...

=back

See respective register_* methods for more details.

=cut

sub import {
    my $pkg = shift;
    $Caller = caller;

    my @exportable = qw(ds_validate);
    my @export = qw(ds_validate);

    for (my $i = 0; $i < @_; $i++) {
        my $arg = $_[$i];
        if (grep {$arg eq $_} @exportable) {
            push @export, $arg unless grep {$arg eq $_} @export;
            next;
        } elsif ($arg =~ /^-?(plugin|type|func|schema|lang)s?$/) {
            my $n = $1 . "s";
                $Import_Adds{$Caller}{$n} //= [];
            $i++;
            push @{ $Import_Adds{$Caller}{$n} },
                ref($_[$i]) eq 'ARRAY' ? @{$_[$i]} : $_[$i];
        } else {
            die "Invalid argument #".($i+1)." in importing Data::Schema: $arg";
        }
    }

    # default export
    no strict 'refs';
    *{$Caller."::$_"} = \&{$pkg."::$_"} for @export;
}

=head1 FAQ

=head2 General

=head3 Why write data schema instead of direct Perl validation code?

It's usually shorter. It's more declarative and thus more readable by non-Perl
programmers. The language syntax is much simpler and thus less error-prone.

=head3 Why use Data::Schema (DS) instead of the other data schema/validation modules?

Some data validation modules (especially web form-oriented ones) only validate
shallow hashes, not deep hashes.

DS schema is pure data structure, without any Perl code. You can write the schema
in YAML/JSON/etc. Also you can more easily manipulate the schema.

DS schemas can be converted to Perl as well as JavaScript, and others.

The DS language encourage schema reuse and organization.

=head2 Syntax

=head3 What do the 'foo*', 'foo[]', 'foo*[]*' symbols mean?

'TYPENAME*' is just a shortcut, equivalent to [TYPENAME, {required=>1}], e.g.
"str*" is equivalent to [str => {required=>1}], only easier to type.

'TYPENAME[]' is a shorcut for [array => {of => TYPENAME}].

There are a few other shortcuts, e.g. '{KEY=>VALUE}', 'A|B', 'A&B'.

You can combine the shortcuts, so for example "(int*[])*" or "int*[]*" is
equivalent to [array => {required=>1, of=>[int => {required=>1}]}]. It basically
says "a required array or required ints". Btw, required means that the value
cannot be undef.

Note that you don't have to use the shortcuts. You can always use the verbose
form.

See L<Data::Schema::Manual::Syntax> for the full syntax explanation.


=head1 SEE ALSO

=head2 Documentation

L<Data::Schema::Manual::Schema> describes the schema language.

L<Data::Schema::Manual::Tutorial> offers introduction and getting started guide.

L<Data::Schema::Manual::Cookbook> contains various examples.

L<Data::Schema::Manual::AddingNewType>

L<Data::Schema::Manual::CreatingNewEmitter>

L<Data::Schema::Manual::CreatingNewFunction>

L<Data::Schema::Manual::AddingLanguage>

L<Data::Schema::Manual::CreatingPlugin>

=head2 Other modules in the Data::Schema family of distributions

L<Data::Schema::Plugin::> namespace is reserved for DS plugins, e.g.
DSP::LoadSchema::YAMLFile to load schemas from YAML files and
DSP::LoadSchema::JSONFile to load schemas from JSON files.

L<Data::Schema::Emitter::> namespace is reserved for DS emitters, those that
convert DS schema to other languages. Currently existing emitters: DSE::Perl,
DSE::Human, DSE::JS, DSE::PHP.

L<Data::Schema::Spec::$VERSION::{Type,Func}> namespaces are reserved for DS type
and function specifications, most are roles. Type and function implementations
will be in Data::Schema::Emitter::$EMITTER::{Type,Func}::*.

L<Data::Schema::Lang::> namespace is reserved for modules that contain
translations. The last part of the qualified name is the 2-letter language code.

L<Data::Schema::Schema::> namespace is reserved for modules that contain DS
schemas. For example, L<Data::Schema::Schema::CPANMeta> validates CPAN META.yml.
L<Data::Schema::Schema::Schema> contains the schema for DS schema itself.

=head2 Modules using Data::Schema

L<Config::Tree> uses Data::Schema to check command-line options and makes it easy
to generate --help/usage information.

L<LUGS::Events::Parser> by Steven Schubiger is apparently one of the first
modules (outside my own of course) which use Data::Schema.

(Your module here).

=head2 Other data validation modules in CPAN

Some other data validation modules on CPAN: L<Data::FormValidator>, L<Data::Rx>,
L<Kwalify>, L<Data::Verifier>.

=cut

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
