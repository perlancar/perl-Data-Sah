#!perl -T

use Test::More tests => 49;

BEGIN {
    my @types = qw(All Array Bool CIStr Either Float Hash Int Str Object); # DateTime
    my @funcs = qw(Std);
    my @schemas = qw(Std Schema);
    my @langs = qw(en);
    my @plugins = qw(LoadSchema::Base);
    my @emitters = qw(Perl Human);
    my @modules;

    use_ok "Data::Schema";

    push @modules, 'Config', 'Util';
    push @modules, 'ParseShortcut';
    push @modules, 'ParseExpr', 'ExecuteExpr', 'Expr';
    push @modules, map {"Type::$_"} @types;
    push @modules, map {"Func::$_"} @funcs;
    push @modules, map {"Lang::$_"} @langs;
    push @modules, map {"Schema::$_"} @schemas;

    for my $e (@emitters) {
        push @modules, "Emitter::$e";
        for my $m ('Config', 'Expr',
                   (map {"Type::$_"} @types),
                   (map {"Func::$_"} @funcs)) {
            push @modules, "Emitter::$e\::$m";
        }
    }

    use_ok "Data::Schema::$_" for @modules;
}

diag( "Testing Data::Schema $Data::Schema::VERSION, Perl $], $^X" );
