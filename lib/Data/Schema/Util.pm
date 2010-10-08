package Data::Schema::Util;
# ABSTRACT: Data::Schema utility routines

use strict;
use warnings;
use Sub::Install qw(install_sub);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       attr attr_conflict attr_alias attr_aliases
                       func func_aliases func_alias
                       rule
               );

=head1 FUNCTIONS

=head2 attr($name, prio => $priority, arg => $schema, aliases => \@aliases OR $alias, sub => $sub)

Used in type specification module (Data::Schema::Type::*).

=cut

sub attr {
    my ($name, %args) = @_;
    my $caller = caller;

    if ($args{sub}) {
        install_sub({code => $args{sub}, into => $caller, as => "attr_$name"});
    } else {
        eval "package $caller; use Any::Moose '::Role'; requires 'attr_$name';";
    }
    install_sub({code => sub { $args{prio} // 50 }, into => $caller, as => "attrprio_$name"});
    install_sub({code => sub { $args{arg}        }, into => $caller, as => "attrarg_$name"});
    for ('alias', 'aliases') {
        attr_aliases($name,
                     ref($args{$_}) eq 'ARRAY' ? $args{$_} : [$args{$_}], $caller)
            if $args{$_};
    }
}

=head2 attr_aliases($name, $aliases[, $caller])

Create attribute alias.

=cut

sub attr_aliases {
    my ($name, $aliases, $caller) = @_;
    $caller //= (caller)[0];

    for (ref($aliases) eq 'ARRAY' ? @$aliases : $aliases) {
        eval
            "package $caller;".
            "sub attr_$_ { shift->attr_$name(\@_) } ".
            "sub attrprio_$_ { shift->attrprio_$name(\@_) } ".
            "sub attrarg_$_ { shift->attrarg_$name(\@_) }";
        $@ and die "Can't make attr alias $_ -> $name: $@";
    }
}

=head2 attr_alias

Alias for B<attr_aliases>.

=cut

sub attr_alias {
    my ($name, $aliases, $pkg) = @_;
    $pkg //= (caller)[0];
    attr_aliases($name, $aliases, $pkg);
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
    for ('alias', 'aliases') {
        func_aliases($name,
                     ref($args{$_}) eq 'ARRAY' ? $args{$_} : [$args{$_}], $caller)
            if $args{$_};
    }
}

=head2 func_aliases($name, $aliases[, $caller])

Create function alias.

=cut

sub func_aliases {
    my ($name, $aliases, $caller) = @_;
    $caller //= (caller)[0];

    for (@$aliases) {
        eval
            "package $caller;".
            "sub func_$_ { shift->func_$name(\@_) } ".
            "sub funcargs_$_ { shift->funcargs_$name(\@_) } ";
        $@ and die "Can't make func alias $_ -> $name: $@";
    }
}

=head2 func_alias

Alias for B<func_aliases>.

=cut

sub func_alias {
    my ($name, $aliases, $pkg) = @_;
    $pkg //= (caller)[0];
    func_aliases($name, $aliases, $pkg);
}

1;
