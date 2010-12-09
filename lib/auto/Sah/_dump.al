package Sah;

use 5.010;
use Data::Dump::OneLine;

sub _dump {
    my $self = shift;
    return Data::Dump::OneLine::dump_one_line(@_);
}

1;
