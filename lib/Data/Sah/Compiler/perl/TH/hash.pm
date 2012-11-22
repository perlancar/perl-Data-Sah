package Data::Sah::Compiler::perl::TH::hash;

use 5.010;
use Log::Any '$log';
use Moo;
extends 'Data::Sah::Compiler::perl::TH';
with 'Data::Sah::Type::hash';

# VERSION

sub handle_type {
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

sub clause_keys {
    my ($self_th, $cd) = @_;
    my $c = $self_th->compiler;

    $c->handle_clause(
        $cd,
        on_term => sub {
            my ($self, $cd) = @_;
            my $cv = $cd->{cl_value};
            my $dt = $cd->{data_term};

            my $jccl;
            {
                local $cd->{ccls} = [];
                local $cd->{args}{return_type} = 'bool';

                if ($cd->{cset}{"keys.restrict"} // 1) {
                    local $cd->{_debug_ccl_note} = "keys.restrict";
                    $c->add_module($cd, "List::Util");
                    $c->add_ccl(
                        $cd,
                        "!defined(List::Util::first {!(\$_ ~~ ".
                            $c->literal([keys %$cv]).")} keys %{$dt})",
                        {
                            err_msg => "TMPERRMSG: keys.restrict",
                        },
                    );
                }
                delete $cd->{ucset}{"keys.restrict"};

                my $cdef = $cd->{cset}{"keys.create_default"} // 1;
                delete $cd->{ucset}{"keys.create_default"};

                for my $k (keys %$cv) {
                    my $sch = $c->main->normalize_schema($cv->{$k});
                    my $kdn = $k; $kdn =~ s/\W+/_/g;
                    my $kdt = "$dt\->{".$c->literal($k)."}";
                    my $icd = $c->compile(
                        data_name    => $kdn,
                        data_term    => $kdt,
                        schema       => $sch,
                        indent_level => $cd->{indent_level}+1,
                        schema_is_normalized => 1,
                        (map { $_=>$cd->{args}{$_} } qw(debug debug_log)),
                    );
                    local $cd->{_debug_ccl_note} = "key: ".$c->literal($k);
                    if ($cdef && defined($sch->[1]{default})) {
                        $c->add_ccl($cd, $icd->{result});
                    } else {
                        $c->add_ccl($cd, "!exists($kdt) || ($icd->{result})");
                    }
                }
                $jccl = $c->join_ccls(
                    $cd, $cd->{ccls}, {err_msg => ''});
            }
            $c->add_ccl($cd, $jccl);
        },
    );
}

sub clause_re_keys {}
sub clause_req_keys {}
sub clause_allowed_keys {}
sub clause_allowed_keys_re {}

1;
# ABSTRACT: perl's type handler for type "hash"

=for Pod::Coverage ^(clause_.+|superclause_.+)$
