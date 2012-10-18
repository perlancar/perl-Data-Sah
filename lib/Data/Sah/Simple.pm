package Data::Sah::Simple;

use 5.010;
use strict;
use warnings;

use Data::Sah;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(normalize_schema validate_schema gen_validator);

sub _ds {
    state $ds = Data::Sah->new;
    $ds;
}

sub _pl {
    _ds()->get_compiler("perl");
}

sub gen_validator {
    my ($schema, $opts) = @_;
    $opts //= {};

    my $cd = _pl()->compile(
        data_name => 'data',
        schema    => $schema,
    );

    eval qq{
        sub {
            my (\$data) = \@_;
            $cd->{result};
        };
    };
}

# VERSION

1;
# ABSTRACT: Simple interface to Data::Sah

=head1 SYNOPSIS

 use Data::Sah::Simple qw(
     gen_validator
 );

 my $s = ['int*', min=>1, max=>10];

 # generate validator
 my $vdr = gen_validator($s, \%opts);

 # validate your data using the generated validator
 $res = $vdr->(5);     # valid
 $res = $vdr->(11);    # invalid
 $res = $vdr->(undef); # invalid
 $res = $vdr->("x");   # invalid


=head1 DESCRIPTION

This module provides more straightforward functional interface to L<Data::Sah>.
For full power and configurability you'll need to use Data::Sah compilers
directly.


=head1 FUNCTIONS

None are exported, but they are exportable.


=head1 SEE ALSO

L<Data::Sah>

=cut
