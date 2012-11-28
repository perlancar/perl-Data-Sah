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
# * multi - bool. fmt can handle multiple values (by adding "one of VALS", "none
# of VALS", or "all of VALS")
#
# * vals - arrayref (default [clause value]). values to fill fmt with.
#
# * items - arrayref. required if type=list. a single ccl or a list of ccls.
#
# add_ccl() is called by clause handlers and handles using .human, translating
# fmt, sprintf(fmt, vals) into 'text', .err_level (adding 'must be %s', 'should
# not be %s'), .is_expr, .op.
sub add_ccl {
    my ($self, $cd, $ccl) = @_;

    my $clause = $cd->{clause} // "";
    $ccl->{type} //= "clause";

    my $hvals = {
        modal_verb     => $self->_xlt($cd, "must"),,
        modal_verb_neg => $self->_xlt($cd, "must not"),
    };
    my $mod="";

    # is .human for desired language specified? if yes, use that instead

    {
        my $lang   = $cd->{args}{lang};
        my $dlang  = $cd->{clset_dlang} // "en_US"; # undef if not in clause
        my $suffix = $lang eq $dlang ? "" : ".alt.lang.$lang";
        if ($clause) {
            delete $cd->{uclset}{$_} for
                grep /\A\Q$clause.human\E(\.|\z)/, keys %{$cd->{uclset}};
            if (defined $cd->{clset}{"$clause.human$suffix"}) {
                $ccl->{type} = 'clause';
                $ccl->{fmt}  = $cd->{clset}{"$clause.human$suffix"};
                goto FILL_FORMAT;
            }
        } else {
            delete $cd->{uclset}{$_} for
                grep /\A\.name(\.|\z)/, keys %{$cd->{uclset}};
            if (defined $cd->{clset}{".name$suffix"}) {
                $ccl->{type} = 'noun';
                $ccl->{fmt}  = $cd->{clset}{".name$suffix"};
                $ccl->{vals} = undef;
                goto FILL_FORMAT;
            }
        }
    }

    goto TRANSLATE unless $clause;

    # handle .is_expr

    if ($cd->{cl_is_expr}) {
        if (!$ccl->{expr}) {
            $ccl->{fmt} = "$clause %(modal_verb)s %s";
        }
    }

    # handle .op

    my $cv   = $cd->{clset}{$clause};
    my $vals = $ccl->{vals} // [$cv];
    my $ie   = $cd->{cl_is_expr};
    my $op   = $cd->{cl_op} // "";
    my $im   = $op =~ /^(and|or|none)$/;
    my $repeat;
    if ($op eq 'not') {
        ($hvals->{modal_verb}, $hvals->{modal_verbneg}) =
            ($hvals->{modal_verb_neg}, $hvals->{modal_verb});
    } elsif ($op eq 'and') {
        if ($ccl->{multi}) {
            if (@$cv == 2) {
                $vals = [sprintf($self->_xlt($cd, "%s and %s"),
                                 $self->literal($cd, $cv->[0]),
                                 $self->literal($cd, $cv->[1]))];
            } else {
                $vals = [sprintf($self->_xlt($cd, "all of %s"),
                                 $self->literal($cd, $cv))];
            }
        } else {
            $ccl->{orig_fmt} = $ccl->{fmt};
            $ccl->{fmt} = "%(modal_verb)s satisfy all of the following";
            $repeat++;
        }
    } elsif ($op eq 'or') {
        if ($ccl->{multi}) {
            if (@$cv == 2) {
                $vals = [sprintf($self->_xlt($cd, "%s or %s"),
                                 $self->literal($cd, $cv->[0]),
                                 $self->literal($cd, $cv->[1]))];
            } else {
                $vals = [sprintf($self->_xlt($cd, "one of %s"),
                                 $self->literal($cd, $cv))];
            }
        } else {
            $ccl->{orig_fmt} = $ccl->{fmt};
            $ccl->{fmt} = "%(modal_verb)s satisfy one of the following";
            $repeat++;
        }
    } elsif ($op eq 'none') {
        if ($ccl->{multi}) {
            ($hvals->{modal_verb}, $hvals->{modal_verbneg}) =
                ($hvals->{modal_verb_neg}, $hvals->{modal_verb});
            if (@$cv == 2) {
                $vals = [sprintf($self->_xlt($cd, "%s nor %s"),
                                 $self->literal($cd, $cv->[0]),
                                 $self->literal($cd, $cv->[1]))];
            } else {
                $vals = [sprintf($self->_xlt($cd, "any of %s"),
                                 $self->literal($cd, $cv))];
            }
        } else {
            $ccl->{orig_fmt} = $ccl->{fmt};
            $ccl->{fmt} = "%(modal_verb)s satisfy none of the following";
            $repeat++;
        }
    }

    if ($repeat) {
        local $cd->{ccls} = [];
        local $cd->{clset}{"$clause.op"};
        local $cd->{cl_op};
        for (@$cv) {
            local $cd->{clset}{$clause} = $_;
            local $cd->{cl_value}       = $_;
            $self->add_ccl(
                $cd, {type=>'clause', fmt=>$ccl->{orig_fmt}, vals=>[$_]});
        }
        $ccl->{items} = $cd->{ccls};
        $ccl->{type}  = 'list';
    }
    $vals = $ie ? $self->expr($cd, $vals) :
        [map {$self->literal($cd, $_)} @$vals];

    # handle .err_level

    if ($ccl->{type} eq 'clause' && 'constraint' ~~ $cd->{cl_meta}{tags}) {
        if (($cd->{clset}{"$clause.err_level"}//'error') eq 'warn') {
            if ($op eq 'not') {
                $hvals->{modal_verb}     = $self->_xlt($cd, "should not");
                $hvals->{modal_verb_neg} = $self->_xlt($cd, "should");
            } else {
                $hvals->{modal_verb}     = $self->_xlt($cd, "should");
                $hvals->{modal_verb_neg} = $self->_xlt($cd, "should not");
            }
        }
    }
    delete $cd->{uclset}{"$clause.err_level"};

  TRANSLATE:

    if (ref($ccl->{fmt}) eq 'ARRAY') {
        $ccl->{fmt}  = [map {$self->_xlt($cd, $_)} @{$ccl->{fmt}}];
    } elsif (!ref($ccl->{fmt})) {
        $ccl->{fmt}  = $self->_xlt($cd, $ccl->{fmt});
    }

  FILL_FORMAT:

    if (ref($ccl->{fmt}) eq 'ARRAY') {
        $ccl->{text} = [map {sprintfn($_, $hvals, @$vals)} @{$ccl->{fmt}}];
    } elsif (!ref($ccl->{fmt})) {
        $ccl->{text} = sprintfn($ccl->{fmt}, $hvals, @$vals);
    }
    delete $ccl->{fmt} unless $cd->{args}{debug};

    push @{$cd->{ccls}}, $ccl;
}

# format ccls to form final result. at the end of compilation, we have a tree of
# ccls. this method accept a single ccl (of type either noun/clause) or an array
# of ccls (which it will join together).
sub format_ccls {
    my ($self, $cd, $ccls) = @_;

    my $f = $cd->{args}{format};
    if ($f eq 'inline_text') {
        $self->_format_ccls_itext($cd, $ccls);
    } else {
        $self->_format_ccls_markdown($cd, $ccls);
    }
}

sub _format_ccls_itext {
    my ($self, $cd, $ccls) = @_;

    local $cd->{args}{mark_fallback} = 0;
    my $c_comma = $self->_xlt($cd, ", ");

    if (ref($ccls) eq 'HASH' && $ccls->{type} =~ /^(noun|clause)$/) {
        # handle a single noun/clause ccl
        my $ccl = $ccls;
        return ref($ccl->{text}) eq 'ARRAY' ? $ccl->{text}[0] : $ccl->{text};
    } elsif (ref($ccls) eq 'HASH' && $ccls->{type} eq 'list') {
        # handle a single list ccl
        my $c_openpar  = $self->_xlt($cd, "(");
        my $c_closepar = $self->_xlt($cd, ")");
        my $c_colon    = $self->_xlt($cd, ": ");
        my $ccl = $ccls;

        my $txt = $ccl->{text}; $txt =~ s/\s+$//;
        return join(
            "",
            $txt,
            $c_colon, $c_openpar,
            join($c_comma, map {$self->_format_ccls_itext($cd, $_)}
                     @{ $ccl->{items} }),
            $c_closepar
        );
    } elsif (ref($ccls) eq 'ARRAY') {
        # handle an array of ccls
        return join($c_comma, map {$self->_format_ccls_itext($cd, $_)} @$ccls);
    } else {
        $self->_die($cd, "Can't format $ccls");
    }
}

sub _format_ccls_markdown {
    my ($self, $cd, $ccls) = @_;

    $self->_die($cd, "Sorry, markdown not yet implemented");
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

    # quantify NOUN (e.g. integer) into 'required integer', 'optional integer',
    # or 'forbidden integer'.

    # my $q;
    # if (!$cd->{clset}{'required.is_expr'} &&
    #         !('required' ~~ $cd->{args}{skip_clause})) {
    #     if ($cd->{clset}{required}) {
    #         $q = 'required %s';
    #     } else {
    #         $q = 'optional %s';
    #     }
    # } elsif ($cd->{clset}{forbidden} && !$cd->{clset}{'forbidden.is_expr'} &&
    #              !('forbidden' ~~ $cd->{args}{skip_clause})) {
    #     $q = 'forbidden %s';
    # }
    # if ($q && @{$cd->{ccls}} && $cd->{ccls}[0]{type} eq 'noun') {
    #     $q = $self->_xlt($cd, $q);
    #     for (ref($cd->{ccls}[0]{text}) eq 'ARRAY' ?
    #              @{ $cd->{ccls}[0]{text} } : $cd->{ccls}[0]{text}) {
    #         $_ = sprintf($q, $_);
    #     }
    # }

    $cd->{result} = $self->format_ccls($cd, $cd->{ccls});
}

sub after_compile {
    my ($self, $cd) = @_;

    setlocale(LC_ALL, $cd->{_orig_locale});
}

1;
# ABSTRACT: Compile Sah schema to human language

=for Pod::Coverage ^(name|literal|expr|add_ccl|format_ccls|check_compile_args|handle_.+|before_.+|after_.+)$

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
