package Data::Schema::Util;
# ABSTRACT: Data::Schema utility routines

use 5.010;
use strict;
use warnings;
use Sub::Install qw(install_sub);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       attr attr_alias attr_conflict attr_codep
                       func func_alias
               );

=head1 FUNCTIONS

=head2 attr($name, prio => $priority, arg => $schema, aliases => \@aliases OR $alias[, code => $code])

Used in type specification module (Data::Schema::Type::*).

=cut

sub attr {
    my ($name, %args) = @_;
    my $caller = caller;

    eval "package $caller; use Any::Moose '::Role'; requires 'attr_$name';";
    if ($args{code}) {
        install_sub({code => $args{code}, into => $caller, as => "attr_$name"});
    }
    install_sub({code => sub {
                     state $names = [$name];
                     if ($_[1]) { push @$names, $_[1] }
                     $names;
                 },
                 into => $caller,
                 as => "attrnames_$name"});
    install_sub({code => sub { $args{prio} // 50 },
                 into => $caller,
                 as => "attrprio_$name"});
    install_sub({code => sub { $args{arg} // undef },
                 into => $caller,
                 as => "attrarg_$name"});
    attr_alias($name, $args{alias}  , $caller);
    attr_alias($name, $args{aliases}, $caller);
}

=head1 attr_alias TARGET => ALIAS | [ALIASES, ...]

Specify that attribute named ALIAS is an alias for TARGET.

You have to specify TARGET attribute first (see B<attr> above).

=cut

sub attr_alias {
    my ($name, $aliases, $caller) = @_;
    $caller //= (caller)[0];
    my @aliases = !$aliases ? () :
        ref($aliases) eq 'ARRAY' ? @$aliases : $aliases;

    for my $alias (@aliases) {
        eval
            "package $caller;".
            "sub attr_$alias { shift->attr_$name(\@_) } ".
            "sub attrprio_$alias { shift->attrprio_$name(\@_) } ".
            "sub attrarg_$alias { shift->attrarg_$name(\@_) } ".
            "sub attralias_${name}__$alias { } ";
        $@ and die "Can't make attr alias $alias -> $name: $@";
    }
}

=head2 attr_conflict ATTR, ATTR, ...

State that specified attributes conflict with one another and cannot
be specified together in a schema. Example:

Example:

 attr_conflict 'set', 'forbidden';
 attr_conflict 'set', 'required';

XXX Not yet implemented.

=cut

sub attr_conflict {
}

=head2 attr_codep ATTR, ATTR, ...

State that specified attributes must be specified together (or none at all).

XXX Not yet implemented.

=cut

sub attr_codep {
}

=head2 func($name, args => [$schema_arg0, $schema_arg1, ...], aliases => \@aliases OR $alias[, code => $code])

Used in function specification module (Data::Schema::Func::*).

=cut

sub func {
    my ($name, %args) = @_;
    my $caller = caller;

    if ($args{code}) {
        install_sub({code => $args{code}, into => $caller, as => "func_$name"});
    } else {
        eval "package $caller; use Any::Moose '::Role'; requires 'func_$name';";
    }
    install_sub({code => sub {
                     state $names = [$name];
                     if ($_[1]) { push @$names, $_[1] }
                     $names;
                 },
                 into => $caller,
                 as => "funcnames_$name"});
    install_sub({code => sub { $args{args} }, into => $caller, as => "funcargs_$name"});
    my @aliases =
        map { (!$args{$_} ? () :
                   ref($args{$_}) eq 'ARRAY' ? @{ $args{$_} } : $args{$_}) }
            qw/alias aliases/;
    func_alias($name, $args{alias}  , $caller);
    func_alias($name, $args{aliases}, $caller);
}

=head1 func_alias TARGET => ALIAS | [ALIASES...]

Specify that function named ALIAS is an alias for TARGET.

You have to specify TARGET function first (see B<func> above).

=cut

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
