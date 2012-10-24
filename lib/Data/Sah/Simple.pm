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

    my ($schema, $opts0) = @_;
    $opts0 //= {};
    my %copts = %$opts0;
    $copts{schema}                 //= $schema;
    $copts{indent_level}           //= 1;
    $copts{data_name}              //= 'data';
    $copts{validator_return_type}  //= 'bool';

    my $do_log = $copts{debug_log} || $copts{debug};
    my $vrt    = $copts{validator_return_type};

    my @code;

    if ($do_log) {
        push @code, "use Log::Any qw(\$log);\n";
    }
    push @code, "sub {\n";
    push @code, "    my (\$data) = \@_;\n";
    if ($do_log) {
        push @code, "    \$log->tracef('-> (validator)(%s) ...', \$data);\n";
        if ($vrt eq 'bool') {
            push @code, "    my \$res = \n";
        }
    }
    if ($vrt ne 'bool') {
        push @code, '    my $err_data = '.($vrt eq 'str' ? "''" : "{}").";\n";
    }
    my $cd = _pl()->compile(%copts);
    push @code, $cd->{result};
    if ($vrt eq 'bool') {
        if ($do_log) {
            push @code, ";\n    \$log->tracef('<- validator() = %s', \$res)";
        }
    } else {
        if ($do_log) {
            push @code, ";\n    \$log->tracef('<- validator() = %s', ".
                "\$err_data)";
        }
        push @code, ";\n    return \$err_data";
    }
    push @code, ";\n}\n";

    my $code = join "", @code;
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

=head2 gen_validator($schema, \%opts) => CODE

Generate validator for C<$schema>. C<%opts> are passed to the Perl schema
compiler.

=head1 SEE ALSO

L<Data::Sah>

=cut
