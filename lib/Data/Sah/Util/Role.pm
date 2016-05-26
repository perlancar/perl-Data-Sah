package Data::Sah::Util::Role;

# DATE
# VERSION

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Sub::Install qw(install_sub);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       has_clause has_clause_alias
                       has_func   has_func_alias
               );

sub has_clause {
    my ($name, %args) = @_;
    my $caller = caller;
    my $into   = $args{into} // $caller;

    if ($args{code}) {
        install_sub({code => $args{code}, into => $into,
                     as => "clause_$name"});
    } else {
        eval "package $into; use Role::Tiny; ".
            "requires 'clause_$name';";
    }
    install_sub({code => sub {
                     state $meta = {
                         names      => [$name],
                         tags       => $args{tags},
                         prio       => $args{prio} // 50,
                         arg        => $args{arg},
                         allow_expr => $args{allow_expr},
                         attrs      => $args{attrs} // {},
                         subschema  => $args{subschema},
                     };
                     $meta;
                 },
                 into => $into,
                 as => "clausemeta_$name"});
    has_clause_alias($name, $args{alias}  , $into);
    has_clause_alias($name, $args{aliases}, $into);
}

sub has_clause_alias {
    my ($name, $aliases, $into) = @_;
    my $caller   = caller;
    $into      //= $caller;
    my @aliases = !$aliases ? () :
        ref($aliases) eq 'ARRAY' ? @$aliases : $aliases;
    my $meta = $into->${\("clausemeta_$name")};

    for my $alias (@aliases) {
        push @{ $meta->{names} }, $alias;
        eval
            "package $into;".
            "sub clause_$alias { shift->clause_$name(\@_) } ".
            "sub clausemeta_$alias { shift->clausemeta_$name(\@_) } ";
        $@ and die "Can't make clause alias $alias -> $name: $@";
    }
}

sub has_func {
    my ($name, %args) = @_;
    my $caller = caller;
    my $into   = $args{into} // $caller;

    if ($args{code}) {
        install_sub({code => $args{code}, into => $into, as => "func_$name"});
    } else {
        eval "package $into; use Role::Tiny; requires 'func_$name';";
    }
    install_sub({code => sub {
                     state $meta = {
                         names => [$name],
                         args  => $args{args},
                     };
                     $meta;
                 },
                 into => $into,
                 as => "funcmeta_$name"});
    my @aliases =
        map { (!$args{$_} ? () :
                   ref($args{$_}) eq 'ARRAY' ? @{ $args{$_} } : $args{$_}) }
            qw/alias aliases/;
    has_func_alias($name, $args{alias}  , $into);
    has_func_alias($name, $args{aliases}, $into);
}

sub has_func_alias {
    my ($name, $aliases, $into) = @_;
    my $caller   = caller;
    $into      //= $caller;
    my @aliases = !$aliases ? () :
        ref($aliases) eq 'ARRAY' ? @$aliases : $aliases;
    my $meta = $into->${\("funcmeta_$name")};

    for my $alias (@aliases) {
        push @{ $meta->{names} }, $alias;
        eval
            "package $into;".
            "sub func_$alias { shift->func_$name(\@_) } ".
            "sub funcmeta_$alias { shift->funcmeta_$name(\@_) } ";
        $@ and die "Can't make func alias $alias -> $name: $@";
    }
}

1;
# ABSTRACT: Sah utility routines for roles

=head1 DESCRIPTION

This module provides some utility routines to be used in roles, e.g.
C<Data::Sah::Type::*> and C<Data::Sah::FuncSet::*>.


=head1 FUNCTIONS

=head2 has_clause($name, %opts)

Define a clause. Used in type roles (C<Data::Sah::Type::*>). Internally it adds
a L<Moo> C<requires> for C<clause_$name>.

Options:

=over 4

=item * arg => $schema

Define schema for clause value.

=item * prio => $priority

Optional. Default is 50. The higher the priority, the earlier the clause will be
processed.

=item * aliases => \@aliases OR $alias

Define aliases. Optional.

=item * code => $code

Optional. Define implementation for the clause. The code will be installed as
'clause_$name'.

=item * into => $package

By default it is the caller package, but can be set to other package.

=back

Example:

 has_clause minimum => (arg => 'int*', aliases => 'min');

=head2 has_clause_alias TARGET => ALIAS | [ALIAS1, ...]

Specify that clause named ALIAS is an alias for TARGET.

You have to define TARGET clause first (see B<has_clause> above).

Example:

 has_clause max_length => ...;
 has_clause_alias max_length => "max_len";

=head2 has_func($name, %opts)

Define a Sah function. Used in function set roles (C<Data::Sah::FuncSet::*>).
Internally it adds a L<Moo> C<requires> for C<func_$name>.

Options:

=over 4

=item * args => [$schema_arg0, $schema_arg1, ...]

Declare schema for arguments.

=item * aliases => \@aliases OR $alias

Optional. Declare aliases.

=item * code => $code

Supply implementation for the function. The code will be installed as
'func_$name'.

=item * into => $package

By default it is the caller package, but can be set to other package.

=back

Example:

 has_func abs => (args => 'num');

=head2 has_func_alias TARGET => ALIAS | [ALIASES...]

Specify that function named ALIAS is an alias for TARGET.

You have to specify TARGET function first (see B<has_func> above).

Example:

 has_func_alias 'atan' => 'arctan';

=cut
