package Data::Sah::Compiler::perl::Coerce::date::str_iso8601;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

use parent qw(Data::Sah::Compiler::perl::Coerce);

sub coerce {
    my $self = shift;
    my $cd = shift;
    my $dt = @_ ? shift : $cd->{args}{data_term};

    my $c = $cd->{compiler};

    my $coerce_cd = {};
    $coerce_cd->{expr_check} = join(
        " && ",
        "!ref($data_term)",
        #                   1=Y        2=M        3=D         4="T" 5=h      6=m        7=s       8="Z"
        "$data_term =~ /\\A([0-9]{4})-([0-9]{2})-([0-9]{2})(?:(T)([0-9]{2}):([0-9]{2}):([0-9]{2})(Z?))?\\z/",
    );

    my $coerce_to = $cd->{coerce_to};
    my $code_epoch = '$4 ? ($8 ? Time::Local::timegm($7, $6, $5, $3, $2-1, $1-1900) : Time::Local::timelocal($7, $6, $5, $3, $2-1, $1-1900)) : Time::Local::timelocal(0, 0, 0, $3, $2-1, $1-1900)';
    if ($coerce_to eq 'int(epoch)') {
        $c->add_module($cd, "Time::Local");
        $coerce_cd->{expr_coerce} = $code_epoch;
    } elsif ($coerce_to eq 'DateTime') {
        $c->add_module($cd, "DateTime");
        $coerce_cd->{expr_coerce} = "DateTime->from_epoch(epoch => $code_epoch, time_zone => \$8 ? 'UTC' : 'local')";
    } elsif ($coerce_to eq 'Time::Moment') {
        $c->add_module($cd, "Time::Moment");
        $coerce_cd->{expr_coerce} = "Time::Moment->from_epoch($epoch)";
    } else {
        die "BUG: Unknown coerce_to value '$cd->{coerce_to}'";
    }

    $coerce_cd;
}

1;
# ABSTRACT: Coerce date from (a subset of) ISO8601 string

=for Pod::Coverage ^(should_coerce|coerce)$

=head1 DESCRIPTION

Currently only the following formats are accepted:

 "YYYY-MM-DD"            ; # date (local time), e.g.: 2016-05-13
 "YYYY-MM-DDThh:mm:ss"   ; # date+time (local time), e.g.: 2016-05-13T22:42:00
 "YYYY-MM-DDThh:mm:ssZ"  ; # date+time (UTC), e.g.: 2016-05-13T22:42:00Z

Subclassed from L<Data::Sah::Compiler::perl::Coerce>.


=head1 METHODS

See parent documentation.
