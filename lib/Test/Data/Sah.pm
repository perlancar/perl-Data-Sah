package Test::Data::Sah;

# DATE
# VERSION

use 5.010;
use strict;
use warnings;

use Data::Sah qw(gen_validator);
use Data::Dump qw(dump);
use Test::More 0.98;

use Exporter qw(import);
our @EXPORT_OK = qw(test_sah_cases);

# XXX support js & human testing too
sub test_sah_cases {
    my $tests = shift;

    my $sah = Data::Sah->new;
    my $plc = $sah->get_compiler('perl');

    for my $test (@$tests) {
        my $v = gen_validator($test->{schema});
        my $res = $v->($test->{input});
        my $name = $test->{name} //
            "data " . dump($test->{input}) . " should".
                ($test->{valid} ? " pass" : " not pass"). " schema " .
                    dump($test->{schema});
        my $testres;
        if ($test->{valid}) {
            $testres = ok($res, $name);
        } else {
            $testres = ok(!$res, $name);
        }
        next if $testres;

        # when test fails, show the validator generated code to help debugging
        my $cd = $plc->compile(schema => $test->{schema});
        diag "schema compilation result:\n----begin generated code----\n",
            explain($cd->{result}), "\n----end generated code----\n",
                "that code should return ", ($test->{valid} ? "true":"false"),
                    " when fed \$data=", dump($test->{input}),
                        " but instead returns ", dump($res);

        # also show the result for return_type=full
        my $vfull = gen_validator($test->{schema}, {return_type=>"full"});
        diag "\nvalidator result (full):\n----begin result----\n",
            explain($vfull->($test->{input})), "----end result----";
    }
}

1;
# ABSTRACT: Test routines for Data::Sah

=head1 FUNCTIONS

=head2 test_sah_cases(\@tests)

