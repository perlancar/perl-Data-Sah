package Data::Sah::Util;

use 5.010;
use strict;
use warnings;
use Sub::Install qw(install_sub);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       has_clause clause_alias clause_conflicts clause_codepends
                       has_func func_alias
               );

sub has_clause {
    my ($name, %args) = @_;
    my $caller = caller;

    eval "package $caller; use Moo::Role; requires 'clause_$name';";
    if ($args{code}) {
        install_sub({code => $args{code}, into => $caller,
                     as => "clause_$name"});
    }
    install_sub({code => sub {
                     state $names = [$name];
                     if ($_[1]) { push @$names, $_[1] }
                     $names;
                 },
                 into => $caller,
                 as => "clausenames_$name"});
    install_sub({code => sub { $args{prio} // 50 },
                 into => $caller,
                 as => "clauseprio_$name"});
    install_sub({code => sub { $args{arg} // undef },
                 into => $caller,
                 as => "clausearg_$name"});
    clause_alias($name, $args{alias}  , $caller);
    clause_alias($name, $args{aliases}, $caller);
}

sub clause_alias {
    my ($name, $aliases, $caller) = @_;
    $caller //= (caller)[0];
    my @aliases = !$aliases ? () :
        ref($aliases) eq 'ARRAY' ? @$aliases : $aliases;

    for my $alias (@aliases) {
        eval
            "package $caller;".
            "sub clause_$alias { shift->clause_$name(\@_) } ".
            "sub clauseprio_$alias { shift->clauseprio_$name(\@_) } ".
            "sub clausearg_$alias { shift->clausearg_$name(\@_) } ".
            "sub clausealias_${name}__$alias { } ";
        $@ and die "Can't make clause alias $alias -> $name: $@";
    }
}

sub clause_conflicts {
    die "Not yet implemented";
}

sub clause_codepends {
    die "Not yet implemented";
}

sub has_func {
    my ($name, %args) = @_;
    my $caller = caller;

    if ($args{code}) {
        install_sub({code => $args{code}, into => $caller, as => "func_$name"});
    } else {
        eval "package $caller; use Moo::Role; requires 'func_$name';";
    }
    install_sub({code => sub {
                     state $names = [$name];
                     if ($_[1]) { push @$names, $_[1] }
                     $names;
                 },
                 into => $caller,
                 as => "funcnames_$name"});
    install_sub({code => sub { $args{args} }, into => $caller,
                 as => "funcargs_$name"});
    my @aliases =
        map { (!$args{$_} ? () :
                   ref($args{$_}) eq 'ARRAY' ? @{ $args{$_} } : $args{$_}) }
            qw/alias aliases/;
    func_alias($name, $args{alias}  , $caller);
    func_alias($name, $args{aliases}, $caller);
}

sub func_alias {
    my ($name, $aliases, $pkg) = @_;
    $pkg //= (caller)[0];
    my @aliases = !$aliases ? () :
        ref($aliases) eq 'ARRAY' ? @$aliases : $aliases;
    for my $alias (@aliases) {
        eval
            "package $pkg;".
            "sub func_$alias { shift->func_$name(\@_) } ".
            "sub funcargs_$alias { shift->funcargs_$name(\@_) } ".
            "sub funcalias_${name}__$alias { } ";
        $@ and die "Can't make func alias $alias -> $name: $@";
    }
}

1;
# ABSTRACT: Sah utility routines

=head1 DESCRIPTION

This module provides some utility routines.


=head1 FUNCTIONS

=head2 has_clause($name, %opts)

Define a clause. Used in type roles (Data::Sah::Type::*). Internally it adds a
'require' for 'clause_$name'.

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

=back

Example:

 has_clause minimum => (arg => 'int*', aliases => 'min');

=head2 clause_alias TARGET => ALIAS | [ALIAS1, ...]

Specify that clause named ALIAS is an alias for TARGET.

You have to define TARGET clause first (see B<has_clause> above).

Example:

 has_clause max_length => ...;
 clause_alias max_length => "maxlen";

=head2 clause_conflict CLAUSE, CLAUSE, ...

State that specified clauses conflict with one another and cannot be specified
together in a schema. Example:

Example:

 clause_conflict 'set', 'forbidden';
 clause_conflict 'set', 'required';

Not yet implemented.

=head2 clause_codepend CLAUSE, CLAUSE, ...

State that specified clauses must be specified together (or none at all).

Example:

 clause_codepend 'foo', 'bar';

Not yet implemented.

=head2 has_func($name, %opts)

Define a Sah function. Used in function set roles (Sah::Func::*). Internally it
adds a 'require func_$name'.

Options:

=over 4

=item * args => [$schema_arg0, $schema_arg1, ...]

Declare schema for arguments.

=item * aliases => \@aliases OR $alias

Optional. Declare aliases.

=item * code => $code

Supply implementation for the function. The code will be installed as
'func_$name'.

=back

Example:

 has_func abs => (args => 'num');

=head2 func_alias TARGET => ALIAS | [ALIASES...]

Specify that function named ALIAS is an alias for TARGET.

You have to specify TARGET function first (see B<has_func> above).

Example:

 func_alias 'atan' => 'arctan';

=cut
