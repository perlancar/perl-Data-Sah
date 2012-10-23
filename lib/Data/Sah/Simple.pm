package Data::Sah::Simple;

use 5.010;
use strict;
use warnings;
use Log::Any '$log';

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
    require SHARYANTO::String::Util;

    my ($schema, $opts) = @_;
    $opts //= {};
    my $rt = $opts->{return_type} // 'bool';

    my %copts = (
        data_name             => 'data',
        schema                => $schema,
        validator_return_type => $rt,
        indent_level          => 1,
    );

    my $code = <<'_';
sub {
    my ($data) = @_;
_
    if ($rt ne 'bool') {
        $code .= '    my $err_data = '.($rt eq 'str' ? "''" : "{}").";\n";
    }
    my $cd = _pl()->compile(%copts);
    $code .= $cd->{result};
    if ($rt ne 'bool') {
        $code .= <<'_';
;
    return $err_data;
_
    }
    $code .= "\n};\n";

    if ($log->is_trace) {
        $log->tracef("validator code:\n%s",
                     SHARYANTO::String::Util::linenum($code));
    }

    my $res = eval $code;
    die "Can't compile validator: $@" if $@;
    $res;
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
