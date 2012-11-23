package Data::Sah::Compiler::human;

use 5.010;
use Moo;
extends 'Data::Sah::Compiler';
use Log::Any qw($log);

use POSIX qw(locale_h);
use Text::sprintfn;

# VERSION

# every type extension is registered here
our %typex; # key = type, val = [clause, ...]

sub name { "human" }

sub check_compile_args {
    my ($self, $args) = @_;

    $self->SUPER::check_compile_args($args);

    my @fmts = ('inline_text', 'markdown');
    $args->{format} //= $fmts[0];
    unless ($args->{format} ~~ @fmts) {
        $self->_die({}, "Unsupported format, use one of: ".join(", ", @fmts));
    }
}

sub literal {
    my ($self, $cd, $val) = @_;

    return $val unless ref($val);

    # for now we use JSON. btw, JSON does obey locale setting, e.g. [1.2]
    # encoded to "[1,2]" in id_ID.
    state $json = do {
        require JSON;
        JSON->new->allow_nonref;
    };

    # XXX for nicer output, perhaps say "empty list" instead of "[]", "empty
    # structure" instead of "{}", etc.
    $json->encode($val);
}

sub expr {
    my ($self, $cd, $expr) = @_;

    # for now we dump expression as is. we should probably parse it first to
    # localize number, e.g. "1.1 + 2" should become "1,1 + 2" in id_ID.

    # XXX for nicer output, perhaps say "the expression X" instead of just "X",
    # especially if X has a variable or rather complex.
    $expr;
}

# translate
sub _xlt {
    my ($self, $cd, $text) = @_;

    my $lang = $cd->{args}{lang};

    return $text if $lang eq 'en_US';
    my $translations;
    {
        no strict 'refs';
        $translations = \%{"Data::Sah::Lang::$lang\::translations"};
    }
    return $translations->{$text} if defined($translations->{$text});
    if ($cd->{args}{mark_fallback}) {
        return "(en_US:$text)";
    } else {
        return $text;
    }
}

# add a compiled clause (ccl), which will be combined at the end of compilation
# to be the final result. args is a hashref with these keys:
#
# * type* - str (default 'clause'). either 'noun', 'clause', 'list' (bulleted
#   list, a clause followed by a list of items, each of them is also a ccl)
#
# * fmt* - str/2-element array. human text which can be used as the first
#   argument to sprintf. string. if type=noun, can be a two-element arrayref to
#   contain singular and plural version of noun.
#
# * expr - bool. fmt can handle .is_expr=1
#
# * multi - bool. fmt can handle .is_multi=1
#
# * vals - arrayref (default [clause value]). values to fill fmt with.
#
# * items - arrayref. required if type=list. a list of ccls.
#
# add_ccl() is called by clause handlers and handles using .human, translating
# fmt, sprintf(fmt, vals) into 'text', .err_level (adding 'must be %s', 'should
# not be %s'), .is_expr, .is_multi & {min,max}_{ok,nok}.
sub add_ccl {
    my ($self, $cd, $ccl) = @_;
    $log->errorf("-> add_ccl(), ccl=%s", $ccl);

    my $clause = $cd->{clause} // "";
    $ccl->{type} //= "clause";

    my $hvals = {
        modal_verb        => '',
        modal_verb_be     => '',
        modal_verb_not    => $self->_xlt($cd, "must not "),
        modal_verb_not_be => $self->_xlt($cd, "must not be "),
    };
    my $mod="";

    # is .human for desired language specified? if yes, use that instead

    {
        my $lang   = $cd->{args}{lang};
        my $dlang  = $cd->{cset_dlang} // "en_US"; # undef if not in clause
        my $suffix = $lang eq $dlang ? "" : ".alt.lang.$lang";
        if ($clause) {
            delete $cd->{ucset}{$_} for
                grep /\A\Q$clause.human\E(\.|\z)/, keys %{$cd->{ucset}};
            if (defined $cd->{cset}{"$clause.human$suffix"}) {
                $ccl->{type} = 'clause';
                $ccl->{fmt}  = $cd->{cset}{"$clause.human$suffix"};
                goto TRANSLATE;
            }
        } else {
            delete $cd->{ucset}{$_} for
                grep /\A\.name(\.|\z)/, keys %{$cd->{ucset}};
            if (defined $cd->{cset}{".name$suffix"}) {
                $ccl->{type} = 'noun';
                $ccl->{fmt}  = $cd->{cset}{".name$suffix"};
                $ccl->{vals} = undef;
                goto TRANSLATE;
            }
        }
    }

    goto TRANSLATE unless $clause;

    # handle .is_expr

    if ($cd->{cl_is_expr}) {
        if (!$ccl->{expr}) {
            $ccl->{fmt} = "$clause %(modal_verb_be)s%s";
        }
    }

    # handle .is_multi, .{min,max}_{ok,nok}

    my $cv = $cd->{cset}{$clause};
    my $vals = $ccl->{vals} // [$cv];
    $log->errorf("TMP:vals=%s", $vals);
    my $ie = $cd->{cl_is_expr};
    my $im = $cd->{cl_is_multi};
    $self->_die($cd, "'$clause.is_multi' attribute set, ".
                    "but value of '$clause' clause not an array")
        if $im && !$ie && ref($cv) ne 'ARRAY';
    my $dmin_ok  = defined($cd->{ucset}{"$clause.min_ok"});
    my $dmax_ok  = defined($cd->{ucset}{"$clause.max_ok"});
    my $dmin_nok = defined($cd->{ucset}{"$clause.min_nok"});
    my $dmax_nok = defined($cd->{ucset}{"$clause.max_nok"});
    my $min_ok   = delete  $cd->{ucset}{"$clause.min_ok"}  // 0;
    my $max_ok   = delete  $cd->{ucset}{"$clause.max_ok"}  // 0;
    my $min_nok  = delete  $cd->{ucset}{"$clause.min_nok"} // 0;
    my $max_nok  = delete  $cd->{ucset}{"$clause.max_nok"} // 0;
    if (!$im &&
            !$dmin_ok && !$dmax_ok &&
                !$dmin_nok && !$dmax_nok) {
        # regular
    } elsif (
        !$im &&
            !$dmin_ok && $dmax_ok && $max_ok==0 &&
                !$dmin_nok && !$dmax_nok) {
        $mod="not";
    } elsif (
        $im &&
            !$dmin_ok && $dmax_ok && $max_ok==0 &&
                !$dmin_nok && !$dmax_nok) {
        $mod = "none";
        $ccl->{orig_fmt} = $ccl->{fmt};
        $ccl->{fmt} = '%(modal_verb)sfail all of the following';
    } elsif (
        $im &&
            !$dmin_ok && !$dmax_ok &&
                !$dmin_nok && (!$dmax_nok || $dmax_nok && $max_nok==0)) {
        if ($ccl->{multi}) {
            if (@$cv == 2) {
                $vals = [sprintf($self->_xlt($cd, "%s and %s"),
                                 $cv->[0], $cv->[1])];
            } else {
                $vals = [sprintf($self->_xlt($cd, "all of %s"),
                                 $self->literal($cd, $cv))];
            }
        } else {
            $mod = "and";
            $ccl->{orig_fmt} = $ccl->{fmt};
            $ccl->{fmt} = '%(modal_verb)ssatisfy all of the following';
        }
    } elsif (
        $im &&
            $dmin_ok && $min_ok==1 && !$dmax_ok &&
                !$dmin_nok && !$dmax_nok) {
        if ($ccl->{multi}) {
            if (@$cv == 2) {
                $vals = [sprintf($self->_xlt($cd, "%s or %s"),
                                 $cv->[0], $cv->[1])];
            } else {
                $vals = [sprintf($self->_xlt($cd, "one of %s"),
                                 $self->literal($cd, $cv))];
            }
        } else {
            $mod = "or";
            $ccl->{orig_fmt} = $ccl->{fmt};
            $ccl->{fmt} = '%(modal_verb)ssatisfy one of the following';
        }
    } elsif ($im) {
        $mod = "other";
            $ccl->{orig_fmt} = $ccl->{fmt};
        $hvals->{min_ok}  = $min_ok;
        $hvals->{max_ok}  = $max_ok;
        $hvals->{min_nok} = $min_nok;
        $hvals->{max_nok} = $max_nok;
        if (!$dmin_nok && !$dmax_nok) {
            $ccl->{fmt} = '%(modal_verb)ssatisfy between '.
                '%(min_ok)d and %(max_ok)d of the following';
        } elsif (!$dmin_ok && !$dmax_ok) {
            $ccl->{fmt} = '%(modal_verb)sfail between '.
                '%(min_nok)d and %(max_nok)d of the following';
        } else {
            $ccl->{fmt} = '%(modal_verb)ssatisfy between '.
                '%(min_ok)d and %(max_ok)d and fail between '.
                    '%(min_nok)d and %(max_nok)d of the following';
        }
    } elsif (0) {
        # XXX handle min_nok .. max_nok
    } else {
        $self->_die($cd,
                    "Unsupported combination of .is_multi/.{min,max}_{ok,nok} ".
                        "for clause $clause");
    }
    if ($mod && $mod ne 'not') {
        local $cd->{ccls} = [];
        local $cd->{cset}{"$clause.min_ok"};
        local $cd->{cset}{"$clause.max_ok"};
        local $cd->{cset}{"$clause.min_nok"};
        local $cd->{cset}{"$clause.max_nok"};
        local $cd->{cset}{"$clause.is_multi"};
        local $cd->{cl_is_multi};
        local $cd->{cl_value};
        for (@$cv) {
            local $cd->{cset}{$clause} = $_;
            local $cd->{cl_value} = $_;
            $self->add_ccl(
                $cd, {type=>'clause', fmt=>$ccl->{orig_fmt},
                      vals=>[$_]});
        }
        $ccl->{items} = $cd->{ccls};
        $ccl->{type}  = 'list';
    }
    $vals = $ie ? $self->expr($cd, $vals) :
        [map {$self->literal($cd, $_)} @$vals];

    # handle .err_level

    if ($ccl->{type} eq 'clause' && 'constraint' ~~ $cd->{cl_meta}{tags}) {
        if (($cd->{cset}{"$clause.err_level"}//'error') eq 'warn') {
            if ($mod eq 'not') {
                $hvals->{modal_verb}        = $self->_xlt($cd,"should not ");
                $hvals->{modal_verb_be}     = $self->_xlt($cd,"should not be ");
                $hvals->{modal_verb_not}    = $self->_xlt($cd,"should ");
                $hvals->{modal_verb_not_be} = $self->_xlt($cd,"should be ");
            } else {
                $hvals->{modal_verb}        = $self->_xlt($cd,"should ");
                $hvals->{modal_verb_be}     = $self->_xlt($cd,"should be ");
                $hvals->{modal_verb_not}    = $self->_xlt($cd,"should not ");
                $hvals->{modal_verb_not_be} = $self->_xlt($cd,"should not be ");
            }
        } else {
            if ($mod eq 'not') {
                $hvals->{modal_verb}        = $self->_xlt($cd,"must not ");
                $hvals->{modal_verb_be}     = $self->_xlt($cd,"must not be ");
                $hvals->{modal_verb_not}    = $self->_xlt($cd,"must ");
                $hvals->{modal_verb_not_be} = $self->_xlt($cd,"must be ");
            }
        }
    }
    delete $cd->{ucset}{"$clause.err_level"};

  TRANSLATE:

    if (ref($ccl->{fmt}) eq 'ARRAY') {
        $ccl->{fmt}  = [map {$self->_xlt($cd, $_)} @{$ccl->{fmt}}];
        $ccl->{text} = [map {sprintfn($_, $hvals, @$vals)} @{$ccl->{fmt}}];
    } elsif (!ref($ccl->{fmt})) {
        $ccl->{fmt}  = $self->_xlt($cd, $ccl->{fmt});
        $ccl->{text} = sprintfn($ccl->{fmt}, $hvals, @$vals);
    }
    delete $ccl->{fmt} unless $cd->{args}{debug};


    push @{$cd->{ccls}}, $ccl;
}

# join ccls to form final result.
sub join_ccls {
    my ($self, $cd, $ccls) = @_;

    local $cd->{args}{mark_fallback} = 0;

    my $c_openpar  = $self->_xlt($cd, "(");
    my $c_closepar = $self->_xlt($cd, ")");
    my $c_colon    = $self->_xlt($cd, ": ");
    my $c_comma    = $self->_xlt($cd, ", ");
    my $c_fullstop = $self->_xlt($cd, ". ");

    my $f = $cd->{args}{format};

    if ($f eq 'inline_text') {
        my @parts;
        for my $ccl (@$ccls) {
            if ($ccl->{type} eq 'list') {
                push @parts,
                    "$ccl->{text}$c_colon$c_openpar".
                        $self->join_ccls($cd, $ccl->{items}).$c_closepar;
            } else {
                push @parts, ref($ccl->{text}) eq 'ARRAY' ?
                    $ccl->{text}[0] : $ccl->{text};
            }
        }
        return join($c_comma, @parts);
    }

    if ($f eq 'markdown') {
        $self->_die($cd, "Sorry, markdown not yet implemented");
    }
}

sub _load_lang_modules {
    my ($self, $cd) = @_;

    my $lang = $cd->{args}{lang};
    die "Invalid language '$lang', please use letters only"
        unless $lang =~ /\A\w+\z/;

    my @modp;
    unless ($lang eq 'en_US') {
        push @modp, "Data/Sah/Lang/$lang.pm";
        for my $cl (@{ $typex{$cd->{type}} // []}) {
            my $modp = "Data/Sah/Lang/$lang/TypeX/$cd->{type}/$cl.pm";
            $modp =~ s!::!/!g; # $cd->{type} might still contain '::'
            push @modp, $modp;
        }
    }
    for (@modp) {
        unless (exists $INC{$_}) {
            $log->trace("Loading $_ ...");
            eval { require $_ };
            if ($@) {
                $log->error("Can't load $_, skipped: $@");
                # negative-cache, so we don't have to try again
                $INC{$_} = undef;
            }
        }
    }
}

sub before_compile {
    my ($self, $cd) = @_;

    # set locale so that numbers etc are printed according to locale (e.g.
    # sprintf("%s", 1.2) prints '1,2' in id_ID).
    $cd->{_orig_locale} = setlocale(LC_ALL);

    # XXX do we need to set everything? LC_ADDRESS, LC_TELEPHONE, LC_PAPER, ...
    my $res = setlocale(LC_ALL, $cd->{args}{locale} // $cd->{args}{lang});
    warn "Unsupported locale $cd->{args}{lang}" unless defined($res);
}

sub before_handle_type {
    my ($self, $cd) = @_;

    $self->_load_lang_modules($cd);
}

sub after_all_clauses {
    my ($self, $cd) = @_;

    # stick default value

    $cd->{result} = $self->join_ccls($cd, $cd->{ccls});
}

sub after_compile {
    my ($self, $cd) = @_;

    setlocale(LC_ALL, $cd->{_orig_locale});
}

1;
# ABSTRACT: Compile Sah schema to human language

=for Pod::Coverage ^(name|literal|expr|add_ccl|join_ccls|check_compile_args|handle_.+|before_.+|after_.+)$

=head1 SYNOPSIS


=head1 DESCRIPTION

This class is derived from L<Data::Sah::Compiler>. It generates human language
text.


=head1 ATTRIBUTES


=head1 METHODS

=head2 new() => OBJ

=head2 $c->compile(%args) => RESULT

Aside from base class' arguments, this class supports these arguments (suffix
C<*> denotes required argument):

=over 4

=item * format => STR (default: C<inline_text>)

Format of text to generate. Either C<inline_text> or C<markdown>. Note that you
can easily convert Markdown to HTML, there are libraries in Perl, JavaScript,
etc to do that.

Sample C<inline_text> output:

 integer, must satisfy all of the following: (divisible by 3, at least 10)

Sample C<markdown> output:

 integer, must satisfy all of the following:

 * divisible by 3
 * at least 10

=back

=head3 Compilation data

This subclass adds the following compilation data (C<$cd>).

Keys which contain compilation state:

=over 4

=back

Keys which contain compilation result:

=over 4

=back

=cut
