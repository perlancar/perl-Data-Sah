package Data::Sah::Compiler::human;

use 5.010;
use Moo;
extends 'Data::Sah::Compiler';
use Log::Any qw($log);

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

    my $lang = $cd->{args}{lang};
    if ($lang ne 'en_US') {
        # a bit too much overhead? disabled. so currently can't do literals
        # before before_handle_type(), which is okay i think.
        #$self->_load_lang_module($cd);

        my $mod = "Data::Sah::Lang::$lang";
        return $mod->literal($cd, $val) if $mod->can("literal");
    }

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

    my $lang = $cd->{args}{lang};
    if ($lang ne 'en_US') {
        # a bit too much overhead? disabled. so currently can't do literals
        # before before_handle_type(), which is okay i think.
        #$self->_load_lang_module($cd);

        my $mod = "Data::Sah::Lang::$lang";
        return $mod->expr($cd, $val) if $mod->can("expr");
    }

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
        return "(en_US*$text)";
    } else {
        return $text;
    }
}

sub _say_req_opt_forbidden {

}

# this handle wrapper adds human clause to ccl. it handles .human,
# excluded_clause, expr + multiple values (.is_multi, .is_expr,
# .{min,max}_{ok,nok}), .human,
sub handle_clause {
    my ($self, $cd, %args) = @_;

    my $clause = $cd->{clause};
    my $th     = $cd->{th};

    $self->_die($cd, "Sorry, .is_multi + .is_expr not yet supported ".
                    "(found in clause $clause)")
        if $cd->{cl_is_expr} && $cd->{cl_is_multi};

    my $cval = $cd->{cset}{$clause};
    $self->_die($cd, "'$clause.is_multi' attribute set, ".
                    "but value of '$clause' clause not an array")
        if $cd->{cl_is_multi} && ref($cval) ne 'ARRAY';
    my $cvals = $cd->{cl_is_multi} ? $cval : [$cval];
    my $occls = $cd->{ccls};
    $cd->{ccls} = [];
    my $i;
    for my $v (@$cvals) {
        local $cd->{cl_value} = $v;
        local $cd->{cl_term}  = $self->literal($v);
        local $cd->{_debug_ccl_note} = "" if $i++;
        $args{on_term}->($self, $cd);
    }
    delete $cd->{ucset}{"$clause.err_msg"};
    if (@{ $cd->{ccls} }) {
        push @$occls, {
            ccl => $self->join_ccls(
                $cd,
                $cd->{ccls},
                {
                    min_ok  => $cd->{cset}{"$clause.min_ok"},
                    max_ok  => $cd->{cset}{"$clause.max_ok"},
                    min_nok => $cd->{cset}{"$clause.min_nok"},
                    max_nok => $cd->{cset}{"$clause.max_nok"},
                },
            ),
            err_level => $cd->{cset}{"$clause.err_level"} // "error",
        };
    }
    $cd->{ccls} = $occls;

    delete $cd->{ucset}{$clause};
    delete $cd->{ucset}{"$clause.err_level"};
    delete $cd->{ucset}{"$clause.min_ok"};
    delete $cd->{ucset}{"$clause.max_ok"};
    delete $cd->{ucset}{"$clause.min_nok"};
    delete $cd->{ucset}{"$clause.max_nok"};
}

# ccl is a hash with these keys:
#
# * type - either 'noun', 'clause', 'clauses'
#
# * human - the resulting human noun/clause(s). string. if type=noun, can be a
# two-element arrayref to contain singular and plural version of name. if
# type=clauses, must be an arrayref containing nested subclauses.
#
# * is_constraint - bool

sub add_ccl {
    my ($self, $cd, $ccl, $opts) = @_;

    # translate
    if ($ccl->{human}) {
        if (ref($ccl->{human}) eq 'ARRAY') {
            $ccl->{human} = [map {$self->_translate($cd, $_)} @{$ccl->{human}}];
        } elsif (!ref($ccl->{human})) {
            $ccl->{human} = $self->_translate($cd, $ccl->{human});
        }
    }

    push @{$cd->{ccls}}, $ccl;
}

# join ccls to handle {min,max}_{ok,nok} and insert error messages. opts =
# {min,max}_{ok,nok}
sub join_ccls {
    "";
}

sub _load_lang_modules {
    my ($self, $cd) = @_;

    my $lang = $self->{args}{lang};
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
}

sub before_handle_type {
    my ($self, $cd) = @_;

    # load language modules
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

 (en_US*the text to be translated)

If you do not want this marker, set the C<mark_fallback> option to 0.

=item * exclude_clause => ARRAY

List of clauses to skip generating human clauses for. If you want simpler human
description text, you can add more clauses here. Example:

 # schema
 [int => {default=>1, between=>[1, 10]}]

 # generated human description in English
 integer, between 1-10, default 1

 # generated human description, with exclude_clause => ['default']
 integer, between 1-10

=back

=head3 Compilation data

This subclass adds the following compilation data (C<$cd>).

Keys which contain compilation state:

=over 4

=item * cset_dlang => STR

Clause set's default language

=back

Keys which contain compilation result:

=over 4

=back

=cut
