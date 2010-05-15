#!/usr/bin/perl

use strict;
use warnings;
use FindBin '$Bin';
use lib "$Bin/../lib";
use Data::Schema qw(Schema::Schema);
use Benchmark;

my $dss = $Data::Schema::Schema::Schema::DS_SCHEMAS->{schema};

my $sch1 = [array=>{minlen=>5, maxlen=>5, elements=>[
  [bool =>{set=>1}],
  [int  =>{set=>1, min=>0, max=>10}],
  [str  =>{set=>1, minlen=>1, maxlen=>10, match=>'\w+'}],
  [array=>{set=>1, minlen=>1, of=>"float"}],
  [hash =>{set=>1, minlen=>1, of=>[either=>{of=>["str", "array"]}]}],
]}];

my $dsn = Data::Schema->new(config=>{compile=>0}, schema=>$dss);
my $dsc = Data::Schema->new(config=>{compile=>1}, schema=>$dss);
my ($csub, $cname) = $dsc->compile($dss);

# test first
$dsn->validate($sch1)->{success} or die;
$dsc->validate($sch1)->{success} or die;
my ($err, $warn);
($err, $warn) = $csub->($sch1); @$err == 0 or die;

timethese(200, {
		 "sch1, compile=0" => sub { $dsn->validate($sch1) },
		 "sch1, compile=1" => sub { $dsc->validate($sch1) },
		 "sch1, csub"      => sub { $csub->($sch1) },
		});

