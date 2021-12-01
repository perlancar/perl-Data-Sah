package Test::Data::Sah::Human;

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Data::Sah;

use Exporter qw(import);

# AUTHORITY
# DATE
# DIST
# VERSION

our @EXPORT_OK = qw(test_human);

sub test_human {
    my %args = @_;
    subtest $args{name} // $args{result}, sub {
        my $sah = Data::Sah->new;
        my $hc = $sah->get_compiler("human");
        my %hargs = (
            schema => $args{schema},
            lang => $args{lang},
            %{ $args{compile_opts} // {} },
        );
        $hargs{format} //= "inline_text";
        my $cd = $hc->compile(%hargs);

        if (defined $args{result}) {
            if (ref($args{result}) eq 'Regexp') {
                like($cd->{result}, $args{result}, 'result');
            } else {
                is($cd->{result}, $args{result}, 'result');
            }
        }
    };
}

1;
# ABSTRACT: Routines to test Data::Sah (human compiler)

=head1 FUNCTIONS

=head2 test_human(%args)
