package Data::Schema::Util;
# ABSTRACT: Data::Schema utility routines

use 5.010;
use strict;
use warnings;
use Sub::Install qw(install_sub);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       attr attr_alias attr_conflict
                       func func_alias
               );

=head1 FUNCTIONS

=head2 attr($name, prio => $priority, arg => $schema, aliases => \@aliases OR $alias[, code => $code])

Used in type specification module (Data::Schema::Type::*).

=cut

sub attr {
    my ($name, %args) = @_;
    my $caller = caller;

    if ($args{code}) {
        install_sub({code => $args{code}, into => $caller, as => "attr_$name"});
    } else {
        eval "package $caller; use Any::Moose '::Role'; requires 'attr_$name';";
    }
    install_sub({code => sub { $args{prio} // 50 }, into => $caller, as => "attrprio_$name"});
    install_sub({code => sub { $args{arg}        }, into => $caller, as => "attrarg_$name"});
    my $aliases = [
        map { (!$args{$_} ? () :
                   ref($args{$_}) eq 'ARRAY' ? @{ $args{$_} } : $args{$_}) }
            qw/alias aliases/
        ];
    install_sub({code => sub { ($name, $aliases) }, into => $caller, as => "attrnames_$name"});
    _install_attr_aliases($name, $aliases, $caller) if @$aliases;
}

sub _install_attr_aliases {
    my ($name, $aliases, $caller) = @_;
    $caller //= (caller)[0];

    for (ref($aliases) eq 'ARRAY' ? @$aliases : $aliases) {
        eval
            "package $caller;".
            "sub attr_$_ { attr_$name(\@_) } ".
            "sub attrprio_$_ { attrprio_$name(\@_) } ".
            "sub attrarg_$_ { attrarg_$name(\@_) } ".
            "sub attrnames_$_ { attrnames_$name(\@_) }";
        $@ and die "Can't make attr alias $_ -> $name: $@";
    }
}

=head1 attr_alias ATTR => TARGET

Specify that attribute named ATTR is an alias for TARGET.

=cut

sub attr_alias {
    my ($name, $alias, $pkg) = @_;
    $pkg //= (caller)[0];
    say "package $pkg; push \@{ (attrnames_$name())[1] }, '$alias';";
    eval "package $pkg; use Data::Dump; dd attrnames_$name(); push \@{ (attrnames_$name())[1] }, '$alias';";
    die "Can't make attr alias $name -> $alias: $@" if $@;
    _install_attr_aliases($name, $alias, $pkg);
}

=head2 attr_conflict ATTR, ATTR, ...

State that specified attributes conflict with one another and cannot
be specified together in a schema.

Not yet implemented.

This is used to help generate DSSS.

=cut

sub attr_conflict {
}


=head2 func($name, args => [$schema_arg0, $schema_arg1, ...], aliases => \@aliases OR $alias)

Used in function specification module (Data::Schema::Func::*).

=cut

sub func {
    my ($name, %args) = @_;
    my $caller = caller;

    eval "package $caller; use Any::Moose '::Role'; requires 'func_$name';";
    install_sub({code => sub { $args{args} }, into => $caller, as => "funcargs_$name"});
    my $aliases = [
        map { (!$args{$_} ? () :
                   ref($args{$_}) eq 'ARRAY' ? @{ $args{$_} } : $args{$_}) }
            qw/alias aliases/
        ];
    install_sub({code => sub { ($name, $aliases) }, into => $caller, as => "funcnames_$name"});
    _install_func_aliases($name, $aliases, $caller) if @$aliases;
}

sub _install_func_aliases {
    my ($name, $aliases, $caller) = @_;
    $caller //= (caller)[0];

    for (@$aliases) {
        eval
            "package $caller;".
            "sub func_$_ { func_$name(\@_) } ".
            "sub funcargs_$_ { funcargs_$name(\@_) } ";
        $@ and die "Can't make func alias $_ -> $name: $@";
    }
}

=head1 func_alias ATTR => TARGET

Specify that function named ATTR is an alias for TARGET.

=cut

sub func_alias {
    my ($name, $alias, $pkg) = @_;
    $pkg //= (caller)[0];
    eval "package $pkg; push \@{ funcnames_$name()[1] }, '$alias';";
    die "Can't make func alias $name -> $alias: $@" if $@;
    _install_func_aliases($name, $alias, $pkg);
}

1;
