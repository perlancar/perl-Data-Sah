#!/usr/bin/perl

use strict;
use warnings;
use FindBin '$Bin';
use lib "$Bin/../lib";
use Data::Schema;
use Benchmark;

my $sch = [array=>{minlen=>5, maxlen=>5, elements=>[
  [bool =>{set=>1}],
  [int  =>{set=>1, min=>0, max=>10}],
  [str  =>{set=>1, minlen=>1, maxlen=>10, match=>'\w+'}],
  [array=>{set=>1, minlen=>1, of=>"float"}],
  [hash =>{set=>1, minlen=>1, of=>[either=>{of=>["str", "array"]}]}],
]}];

my $data1 = [ "TRUE", 5, "jinny", [1.1, 2.2], {a=>1, b=>[]} ];
my $data2 = [ [], -1, "     ", [1.1, "a"], {a=>{}, b=>[]}, "extra" ];

my $dsn = Data::Schema->new(config=>{compile=>0});
my $dsc = Data::Schema->new(config=>{compile=>1});
my ($csub, $cname) = $dsc->compile($sch);

# test first
$dsn->validate($data1, $sch)->{success} or die;
$dsn->validate($data2, $sch)->{success} and die;
$dsc->validate($data1, $sch)->{success} or die;
$dsc->validate($data2, $sch)->{success} and die;
my ($err, $warn);
($err, $warn) = $csub->($data1); @$err == 0 or die;
($err, $warn) = $csub->($data2); @$err == 0 and die;

timethese(700, {
		 "valid  , compile=0" => sub { $dsn->validate($data1, $sch) },
		 "invalid, compile=0" => sub { $dsn->validate($data2, $sch) },
		 "valid  , compile=1" => sub { $dsc->validate($data1, $sch) },
		 "invalid, compile=1" => sub { $dsc->validate($data2, $sch) },
		 "valid  , csub" => sub { $csub->($data1) },
		 "invalid, csub" => sub { $csub->($data2) },
		});
