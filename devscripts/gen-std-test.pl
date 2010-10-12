#!/usr/bin/perl -w

use 5.010;
use autodie;
use strict;
use FindBin '$Bin';
use lib "$Bin/../lib";

use Data::Schema;
use File::Slurp;
use JSON;
use YAML::XS;

my $time = time;
my %covered_types;
my %covered_attrs;
my @tests;
my $type;

my $ds = Data::Schema->new;

# generate tests for a certain type
sub gent_type($$&) {
    my ($type0, $aliases, $sub) = @_;
    $type = $type0;
    $covered_types{$type}++ and
        die "BUG: tests for type `$type` generated twice!";
    for (@$aliases) {
        $covered_types{$_}++ and
            die "BUG: tests for type `$_` (alias for $type) generated twice!";
    }
    @tests = ();
    $sub->();
    my $i = 0;
    for (@tests) { $_->{no} = ++$i }
    # XXX recheck whether we have covered all attributes
    my $t = {date => $time,
             date_human => scalar(localtime $time),
             type => $type, aliases => $aliases,
             num_tests => scalar(@tests), tests => \@tests};
    write_file("$Bin/../t-std/$type.json", to_json($t));
    write_file("$Bin/../t-std/$type.yaml", Dump($t));
}

sub addt_basic {
    # XXX add juga undef, selalu valid
    my %args = @_;
    my $i = 0;
    for (@{ $args{invalid_data} }) {
        $i++;
        push @tests, {
            data => $_,
            name => "$type basic test, invalid data #$i",
            success => 1,
            valid => 0,
        };
    }
    $i = 0;
    for (@{ $args{valid_data} }) {
        $i++;
        push @tests, {
            data => $_,
            name => "$type basic, valid data #$i",
            success => 1,
            valid => 1,
        };
    }
}

sub addt_required {

}

gent_type(
    "int", ["integer"],
    sub {
        #push @tests, {name=>'basic'}, ;
        addt_basic(valid_data  =>[0, 1.0, -2],
                   invalid_data=>[0.1, "", [], {}]);
        addt_required();
    });

gent_type(
    "str", ["string"],
    sub {

    });

gent_type(
    "array", [],
    sub {

    });

# XXX recheck whether we have covered all types

__END__
