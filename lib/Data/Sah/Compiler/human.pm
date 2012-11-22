package Data::Sah::Compiler::human;

use 5.010;
use Moo;
extends 'Data::Sah::Compiler';
use Log::Any qw($log);

use POSIX qw(locale_h);

# VERSION

# every type extension is registered here
our %typex; # key = type, val = [clause, ...]

sub name { "human" }

sub check_compile_args {
    my ($self, $args) = @_;

    $self->SUPER::check_compile_args($args);

    $args->{mark_fallback} //= 1;
    for ($args->{lang}) {
        $_ //= $ENV{LANG} // $ENV{LANGUAGE} // "en_US";
        s/\W.*//; # LANG=en_US.UTF-8, LANGUAGE=en_US:en
    }
}

sub literal {
    my ($self, $cd, $val) = @_;

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

sub _translate {
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
# to be the final result. args is a hashref with these keys (*=required):
#
# * type* - str. either 'noun', 'clause', 'list' (bulleted list, a clause
#   followed by a list of items, each of them is also a ccl)
#
# * fmt* - str/2-element array. human text which can be used as the first
#   argument to sprintf. string. if type=noun, can be a two-element arrayref to
#   contain singular and plural version of noun.
#
# * is_constraint - bool (default 0). if true, state that the clause is a
#   constraint and can be prefixed with 'must be %s', 'should be %s', 'must not
#   be %s', 'should not be %s'.
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

    my $clause = $cd->{clause} // "";
    my $lang   = $cd->{args}{lang};
    my $dlang  = $cd->{cset_dlang} // "en_US"; # undef if not in clause handler

    # is .human for desired language specified? if yes, use that instead

    delete $cd->{ucset}{$_} for
        grep /\A\Q$clause.human\E(\.|\z)/, keys %{$cd->{ucset}};
    my $suff = $lang eq $dlang ? "" : ".alt.lang.$lang";
    if (defined $cd->{cset}{"$clause.human$suff"}) {
        $ccl = {
            type          => 'clause',
            fmt           => $cd->{cset}{"$clause.human$suff"},
            is_constraint => 0,
            vals          => $ccl->{vals},
        };
        goto TRANSLATE;
    }

    goto TRANSLATE unless $clause;

    # handle .is_multi, .{min,max}_{ok,nok}, .is_expr

    my $cv = $cd->{cl_value};
    $self->_die($cd, "'$clause.is_multi' attribute set, ".
                    "but value of '$clause' clause not an array")
        if $cd->{cl_is_multi} && ref($cv) ne 'ARRAY';

    # XXX

    # handle .err_level

    delete $cd->{ucset}{$clause};
    delete $cd->{ucset}{"$clause.err_level"};
    delete $cd->{ucset}{"$clause.min_ok"};
    delete $cd->{ucset}{"$clause.max_ok"};
    delete $cd->{ucset}{"$clause.min_nok"};
    delete $cd->{ucset}{"$clause.max_nok"};

  TRANSLATE:

    my $vals = $ccl->{vals} // [$cv];
    if (ref($ccl->{fmt}) eq 'ARRAY') {
        $ccl->{fmt}  = [map {$self->_translate($cd, $_)} @{$ccl->{fmt}}];
        $ccl->{text} = [map {sprintf($_, @$vals)} @{$ccl->{fmt}}];
    } elsif (!ref($ccl->{fmt})) {
        $ccl->{fmt}  = $self->_translate($cd, $ccl->{fmt});
        $ccl->{text} = sprintf($ccl->{fmt}, @$vals);
    }
    delete $ccl->{fmt} unless $cd->{args}{debug};

    push @{$cd->{ccls}}, $ccl;
}

# join ccls to form final result.
sub join_ccls {
    "";
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
    my $res = setlocale(LC_ALL, $cd->{args}{lang});
    warn "Unsupported locale $cd->{args}{lang}" unless defined($res);
}

sub before_handle_type {
    my ($self, $cd) = @_;

    $self->_load_lang_modules($cd);
}

sub before_all_clauses {
    my ($self, $cd) = @_;
}

sub before_clause {
    my ($self, $cd) = @_;

    # XXX a more human-friendly representation
    $cd->{cl_human} = $cd->{cl_is_expr} ? $cd->{cl_term} : $cd->{cl_value};
}

sub after_clause {
    my ($self, $cd) = @_;

    undef $cd->{cl_human};
}

sub after_all_clauses {
    my ($self, $cd) = @_;

    # join ccls into sentence/paragraph/whatever

    # stick default value

    #$cd->{result} = $self->join_ccls($cd, $cd->{ccls}, {err_msg => ''});
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

=item * lang => STR (default: from LANG/LANGUAGE or C<en_US>)

Desired output language. Defaults (and falls back to) C<en_US> since that's the
language the text in the human strings are written in.

=item * mark_fallback => BOOL (default: 1)

If a piece of text is not found in desired language, C<en_US> version of the
text will be used but using this format:

 (en_US:the text to be translated)

If you do not want this marker, set the C<mark_fallback> option to 0.

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
