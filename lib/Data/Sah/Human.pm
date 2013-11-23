package Data::Sah::Human;

use 5.010;
use strict;
use warnings;
use Log::Any qw($log);

our $Log_Validator_Code = $ENV{LOG_SAH_VALIDATOR_CODE} // 0;

# VERSION

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(gen_human_msg);

sub gen_human_msg {
    require Data::Sah;

    my ($schema, $opts) = @_;

    state $hc = Data::Sah->new->get_compiler("human");

    my %args = (schema => $schema, %{$opts // {}});
    my $opt_source = delete $args{source};

    $args{log_result} = 1 if $Log_Validator_Code;

    my $cd = $hc->compile(%args);
    $opt_source ? $cd : $cd->{result};
}

1;
# ABSTRACT: Some functions to use Data::Sah human compiler

=head1 SYNOPSIS

 use Data::Sah::Human qw(gen_human_msg);

 say gen_human_msg(["int*", min=>2]); # -> "Integer, minimum 2"


=head1 DESCRIPTION


=head1 FUNCTIONS

None exported by default.

=head2 gen_human_msg($schema, \%opts) => STR (or ANY)

Compile schema using human compiler and return the result.

Known options (unknown ones will be passed to the compiler):

=over

=item * source => BOOL (default: 0)

If set to true, will return raw compilation result.

=back


=head1 ENVIRONMENT

L<LOG_SAH_VALIDATOR_CODE>


=head1 SEE ALSO

L<Data::Sah>, L<Data::Sah::Compiler::human>.

=cut
