#!perl -T

use 5.010;
use strict;
use warnings;

use Data::Sah;
use File::chdir;
use FindBin qw($Bin);
use Test::More 0.98;
use YAML::Syck qw(LoadFile);
$YAML::Syck::ImplicitTyping = 1;

my $dir;
for ("$Bin/t-std", "$Bin/../t-std") {
    if (-d) {
        $dir = $_;
        last;
    }
}
die "Can't find t-std dir" unless $dir;
$CWD = $dir;

my $sah = Data::Sah->new;

subtest "string shortcuts" => sub {
    my $yaml = LoadFile("00-string_shortcuts.yaml");
    my $i = 0;
    for my $test (@{ $yaml->{tests} }) {
        is_deeply($sah->parse_string_shortcuts($test->{input}), $test->{result},
                  $test->{name} // $test->{input});
        $i++;
    }
};

subtest "normalize" => sub {
    my $yaml = LoadFile("00-normalize.yaml");
    my $i = 0;
    for my $test (@{ $yaml->{tests} }) {
        eval {
            is_deeply($sah->normalize_schema($test->{input}), $test->{result},
                      $test->{name} // $sah->_dump($test->{input}));
            $i++;
        };
        my $eval_err = $@;
        if ($test->{dies}) {
            ok($eval_err, "dies");
        } else {
            ok(!$eval_err, "doesn't die")
                or diag $eval_err;
        }
    }
};

done_testing();
