package Data::Sah::Compiler::perl::TH::hash;

use 5.010;
use Log::Any '$log';
use Moo;
extends 'Data::Sah::Compiler::perl::TH';
with 'Data::Sah::Type::hash';

# VERSION

sub handle_type_check {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    my $dt = $cd->{data_term};
    $cd->{_ccl_check_type} = "ref($dt) eq 'HASH'";
}

my $FRZ = "Storable::freeze";

sub superclause_comparable {
    my ($self, $which, $cd) = @_;
    my $c = $self->compiler;

    $c->handle_clause(
        $cd,
        on_term => sub {
            my ($self, $cd) = @_;
            my $ct = $cd->{cl_term};
            my $dt = $cd->{data_term};

            # Storable is chosen because it's core and fast. ~~ is not very
            # specific.
            $c->add_module($cd, 'Storable');

            if ($which eq 'is') {
                $c->add_ccl($cd, "$FRZ($dt) eq $FRZ($ct)");
            } elsif ($which eq 'in') {
                $c->add_ccl($cd, "$FRZ($dt) ~~ [map {$FRZ(\$_)} \@{ $ct }]");
            }
        },
    );
}

sub superclause_has_elems {
    my ($self_th, $which, $cd) = @_;
    my $c = $self_th->compiler;

    $c->handle_clause(
        $cd,
        on_term => sub {
            my ($self, $cd) = @_;
            my $cv = $cd->{cl_value};
            my $ct = $cd->{cl_term};
            my $dt = $cd->{data_term};

            if ($which eq 'len') {
                $c->add_ccl($cd, "keys(\%{$dt}) == $ct");
            } elsif ($which eq 'min_len') {
                $c->add_ccl($cd, "keys(\%{$dt}) >= $ct");
            } elsif ($which eq 'max_len') {
                $c->add_ccl($cd, "keys(\%{$dt}) <= $ct");
            } elsif ($which eq 'len_between') {
                if ($cd->{cl_is_expr}) {
                    $c->add_ccl(
                        $cd, "keys(\%{$dt}) >= $ct\->[0] && ".
                            "keys(\%{$dt}) >= $ct\->[1]");
                } else {
                    # simplify code
                    $c->add_ccl(
                        $cd, "keys(\%{$dt}) >= $cv->[0] && ".
                            "keys(\%{$dt}) <= $cv->[1]");
                }
            #} elsif ($which eq 'has') {
            } elsif ($which eq 'each_index' || $which eq 'each_elem') {
                $self_th->gen_each($which, $cd, "keys(\%{$dt})",
                                   "values(\%{$dt})");
            #} elsif ($which eq 'check_each_index') {
            #} elsif ($which eq 'check_each_elem') {
            #} elsif ($which eq 'uniq') {
            #} elsif ($which eq 'exists') {
            }
        },
    );
}

sub clause_keys {}
sub clause_re_keys {}
sub clause_req_keys {}
sub clause_allowed_keys {}
sub clause_allowed_keys_re {}

1;
# ABSTRACT: perl's type handler for type "array"

=cut
