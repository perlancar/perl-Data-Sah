use Data::Dumper;
use strict;
use warnings;
use Scalar::Util qw/tainted/;
use Clone qw/clone/;

our $TEST_COMPILED = 0; # 0 (both use noncompiled version), 1 (noncompiled+compiled), or 2 (both use compiled version)

$Data::Dumper::Indent = 0;
$Data::Dumper::Terse = 1;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Purity = 0;

my $Default_DS_NoCompile;
my $Default_DS_Compile;

sub _init_default_ds {
    if (!$Default_DS_NoCompile) { $Default_DS_NoCompile = Data::Schema->new(config=>{compile=>0}) }
    if (!$Default_DS_Compile  ) { $Default_DS_Compile   = Data::Schema->new(config=>{compile=>1}) }
}

# test validation on 2 variant: compiled and uncompiled
sub test_validate($$$$$) {
    my ($data, $schema, $test_name, $ds_user, $sub) = @_;
    _init_default_ds();
    my ($ds_compile, $ds_nocompile);
    if ($ds_user) {
	if ($ds_user->config->compile) {
	    $ds_compile = $ds_user;
	    $ds_nocompile = clone($ds_user);
	    $ds_nocompile->config->compile(0);
	} else {
	    $ds_nocompile = $ds_user;
	    $ds_compile = clone($ds_user);
	    $ds_compile->config->compile(1);
	}
	#print "ds: ".Dumper($ds_nocompile)."\n";
	#print "ds_compile  : ".Dumper($ds_compile)."\n";
    } else {
	$ds_nocompile = $Default_DS_NoCompile;
	$ds_compile   = $Default_DS_Compile;
    }
    #print "\$ds_nocompile tainted? ", tainted($ds_nocompile), "\n";
    #print "\$ds_compile tainted? ", tainted($ds_compile), "\n";

    my $res_nocompile;
    my $res_compile;
    $res_nocompile = $ds_nocompile->validate($data, $schema) if $TEST_COMPILED < 2;
    $res_compile   = $ds_compile  ->validate($data, $schema) if $TEST_COMPILED > 0;

    if ($TEST_COMPILED == 0) {
        $sub->($res_nocompile, $test_name, $ds_nocompile);
        $sub->($res_nocompile, "$test_name (ALSO NOT COMPILED)", $ds_nocompile);
    } elsif ($TEST_COMPILED == 1) {
        $sub->($res_nocompile, $test_name, $ds_nocompile);
        $sub->($res_compile  , "$test_name (compiled)", $ds_compile);
    } else {
        $sub->($res_compile, "$test_name (ALSO COMPILED)", $ds_compile);
        $sub->($res_compile, "$test_name (compiled)", $ds_compile);
    }
}

sub valid($$$;$$) {
    my ($data, $schema, $test_name, $ds, $sub) = @_;
    #print "valid(".Dumper($data).", ".Dumper($schema).", '$test_name', ".($ds // "undef").")\n";
    test_validate($data, $schema, $test_name, $ds,
		  sub {
		      my ($res, $test_name, $ds) = @_;
		      ok($res && $res->{success}, $test_name);
		      if ($sub) { $sub->(@_) }
		  });
}

sub invalid($$$;$$) {
    my ($data, $schema, $test_name, $ds, $sub) = @_;
    #print "invalid(".Dumper($data).", ".Dumper($schema).", '$test_name', ".($ds // "undef").")\n";
    test_validate($data, $schema, $test_name, $ds,
		  sub {
		      my ($res, $test_name, $ds) = @_;
		      ok($res && !$res->{success}, $test_name);
		      if ($sub) { $sub->(@_) }
		  });
}

sub validate_is($$$$;$$) {
    my ($data, $schema, $exp_res, $test_name, $ds, $sub) = @_;
    #print "validate_is(".Dumper($data).", ".Dumper($schema).", '$test_name', ".($ds // "undef").")\n";
    test_validate($data, $schema, $test_name, $ds,
		  sub {
		      my ($res, $test_name, $ds) = @_;
		      ok($res && $res->{success}, "$test_name (is_success)");
		      is_deeply($res->{result}, $exp_res, "$test_name (result)");
		      if ($sub) { $sub->(@_) }
		  });
}

sub test_comparable($$$$$;$) {
    my ($type, $valid1, $valid2, $invalid1, $invalid2, $ds) = @_;
    for (qw(one_of
            is_one_of
            )) { # XXX enum
        valid($valid1, [$type => {$_=>[$valid1, $valid2]}], "comparable:$type:$_ 1", $ds);
        valid($valid2, [$type => {$_=>[$valid1, $valid2]}], "comparable:$type:$_ 2", $ds);
        invalid($invalid1, [$type => {$_=>[$valid1, $valid2]}], "comparable:$type:$_ 3", $ds);
        invalid($invalid2, [$type => {$_=>[$valid1, $valid2]}], "comparable:$type:$_ 4", $ds);
    }
    for (qw(isnt_one_of
            not_one_of
            )) {
        valid($valid1, [$type => {$_=>[$invalid1, $invalid2]}], "comparable:$type:$_ 1", $ds);
        valid($valid2, [$type => {$_=>[$invalid1, $invalid2]}], "comparable:$type:$_ 2", $ds);
        invalid($invalid1, [$type => {$_=>[$invalid1, $invalid2]}], "comparable:$type:$_ 3", $ds);
        invalid($invalid2, [$type => {$_=>[$invalid1, $invalid2]}], "comparable:$type:$_ 4", $ds);
    }
    for (qw(is)) {
        valid($valid1, [$type => {$_=>$valid1}], "comparable:$type:$_ 1", $ds);
        invalid($valid2, [$type => {$_=>$valid1}], "comparable:$type:$_ 2", $ds);
    }
    for (qw(isnt
            not)) {
        valid($valid1, [$type => {$_=>$invalid1}], "comparable:$type:$_ 1", $ds);
        valid($valid2, [$type => {$_=>$invalid1}], "comparable:$type:$_ 2", $ds);
        invalid($invalid1, [$type => {$_=>$invalid1}], "comparable:$type:$_ 3", $ds);
        valid($invalid2, [$type => {$_=>$invalid1}], "comparable:$type:$_ 4", $ds);
    }
}

sub test_sortable($$$$;$) {
    my ($type, $a, $b, $c, $ds) = @_;
    for (qw(min ge)) {
        invalid($a, [$type => {$_=>$b}], "sortable:$type:$_ 1", $ds);
        valid($b, [$type => {$_=>$b}], "sortable:$type:$_ 2", $ds);
        valid($c, [$type => {$_=>$b}], "sortable:$type:$_ 3", $ds);
    }
    for (qw(max le)) {
        valid($a, [$type => {$_=>$b}], "sortable:$type:$_ 1", $ds);
        valid($b, [$type => {$_=>$b}], "sortable:$type:$_ 2", $ds);
        invalid($c, [$type => {$_=>$b}], "sortable:$type:$_ 3", $ds);
    }
    for (qw(minex gt)) {
        invalid($a, [$type => {$_=>$b}], "sortable:$type:$_ 1", $ds);
        invalid($b, [$type => {$_=>$b}], "sortable:$type:$_ 2", $ds);
        valid($c, [$type => {$_=>$b}], "sortable:$type:$_ 3", $ds);
    }
    for (qw(maxex lt)) {
        valid($a, [$type => {$_=>$b}], "sortable:$type:$_ 1", $ds);
        invalid($b, [$type => {$_=>$b}], "sortable:$type:$_ 2", $ds);
        invalid($c, [$type => {$_=>$b}], "sortable:$type:$_ 3", $ds);
    }
    valid($a, [$type => {between=>[$a,$b]}], "sortable:$type:between 1", $ds);
    valid($b, [$type => {between=>[$a,$b]}], "sortable:$type:between 2", $ds);
    invalid($c, [$type => {between=>[$a,$b]}], "sortable:$type:between 3", $ds);
}

sub test_len($$$$;$) {
    my ($type, $len1, $len2, $len3, $ds) = @_;
    for(qw(minlength minlen min_length minlen)) {
        invalid($len1, [$type => {$_=>2}], "len:$type:$_ 1", $ds);
        valid($len2, [$type => {$_=>2}], "len:$type:$_ 2", $ds);
        valid($len3, [$type => {$_=>2}], "len:$type:$_ 3", $ds);
    }
    for(qw(maxlength maxlen max_length maxlen)) {
        valid($len1, [$type => {$_=>2}], "len:$type:$_ 1", $ds);
        valid($len2, [$type => {$_=>2}], "len:$type:$_ 2", $ds);
        invalid($len3, [$type => {$_=>2}], "len:$type:$_ 3", $ds);
    }
    for(qw(len_between length_between)) {
        valid($len1, [$type => {$_=>[1,2]}], "len:$type:$_ 1", $ds);
        valid($len2, [$type => {$_=>[1,2]}], "len:$type:$_ 2", $ds);
        invalid($len3, [$type => {$_=>[1,2]}], "len:$type:$_ 3", $ds);
    }
    for(qw(len length)) {
        invalid($len1, [$type => {$_=>2}], "len:$type:$_ 1", $ds);
        valid($len2, [$type => {$_=>2}], "len:$type:$_ 2", $ds);
        invalid($len3, [$type => {$_=>2}], "len:$type:$_ 3", $ds);
    }
}

# attrhash1 validates $data, but attrhash2 doesn't
sub test_deps($$$) {
    my ($type, $data, $attrhash1, $attrhash2) = @_;

    for (qw(deps dep)) {
	# 1dep, match
	valid  ($data, [$type => {$_=>[[ $type, $type ]]}], "$type:$_ 1");
	valid  ($data, [$type => {$_=>[[ $type, [$type=>$attrhash1] ]]}], "$type:$_ 2");
	valid  ($data, [$type => {$_=>[[ [$type=>$attrhash1], $type ]]}], "$type:$_ 3");
	valid  ($data, [$type => {$_=>[[ [$type=>$attrhash1], [$type=>$attrhash1] ]]}], "$type:$_ 4");
	invalid($data, [$type => {$_=>[[ [$type=>$attrhash1], [$type=>$attrhash2] ]]}], "$type:$_ 5");

	# 1dep, not match, right-side schema don't matter
	valid  ($data, [$type => {$_=>[[ [$type=>$attrhash2], $type ]]}], "$type:$_ 6");
	valid  ($data, [$type => {$_=>[[ [$type=>$attrhash2], [$type=>$attrhash1] ]]}], "$type:$_ 7");
	valid  ($data, [$type => {$_=>[[ [$type=>$attrhash2], [$type=>$attrhash2] ]]}], "$type:$_ 8");

	# 2dep, 1 match, 1 not match (right-side schema don't matter for second dep)
	valid  ($data, [$type => {$_=>[[ [$type=>$attrhash1], $type ], [ [$type=>$attrhash2], $type ]]}], "$type:$_ 9a");
	valid  ($data, [$type => {$_=>[[ [$type=>$attrhash1], $type ], [ [$type=>$attrhash2], [$type=>$attrhash1] ]]}], "$type:$_ 9b");
	valid  ($data, [$type => {$_=>[[ [$type=>$attrhash1], $type ], [ [$type=>$attrhash2], [$type=>$attrhash2] ]]}], "$type:$_ 9c");
	valid  ($data, [$type => {$_=>[[ [$type=>$attrhash1], [$type=>$attrhash1] ], [ [$type=>$attrhash2], $type ]]}], "$type:$_ 10a");
	valid  ($data, [$type => {$_=>[[ [$type=>$attrhash1], [$type=>$attrhash1] ], [ [$type=>$attrhash2], [$type=>$attrhash1] ]]}], "$type:$_ 10b");
	valid  ($data, [$type => {$_=>[[ [$type=>$attrhash1], [$type=>$attrhash1] ], [ [$type=>$attrhash2], [$type=>$attrhash2] ]]}], "$type:$_ 10c");
	invalid($data, [$type => {$_=>[[ [$type=>$attrhash1], [$type=>$attrhash2] ], [ [$type=>$attrhash2], $type ]]}], "$type:$_ 11a");
	invalid($data, [$type => {$_=>[[ [$type=>$attrhash1], [$type=>$attrhash2] ], [ [$type=>$attrhash2], [$type=>$attrhash1] ]]}], "$type:$_ 11b");
	invalid($data, [$type => {$_=>[[ [$type=>$attrhash1], [$type=>$attrhash2] ], [ [$type=>$attrhash2], [$type=>$attrhash2] ]]}], "$type:$_ 11c");
    }
}

1;
