package Data::Sah::Compiler::Prog;

use 5.010;
use Moo;
extends 'Data::Sah::Compiler';
use Log::Any qw($log);

# VERSION

#use Digest::MD5 qw(md5_hex);

# human compiler, to produce error messages
has hc => (is => 'rw');

# subclass should provide a default, choices: 'shell', 'c', 'ini', 'cpp'
has comment_style => (is => 'rw');

has var_sigil => (is => 'rw', default => sub {''});

sub init_cd {
    my ($self, %args) = @_;

    my $cd = $self->SUPER::init_cd(%args);
    $cd->{vars} = {};

    my $hc = $self->hc;
    if (!$hc) {
        $hc = $self->main->get_compiler("human");
        $self->hc($hc);
    }

    if (my $ocd = $cd->{outer_cd}) {
        $cd->{subs}    = $ocd->{subs};
        $cd->{modules} = $ocd->{modules};
        $cd->{_hc}     = $ocd->{_hc};
        $cd->{_hcd}    = $ocd->{_hcd};
    } else {
        $cd->{subs}    = [];
        $cd->{modules} = [];
        $cd->{_hc}     = $hc;
    }

    $cd;
}

sub check_compile_args {
    my ($self, $args) = @_;

    $self->SUPER::check_compile_args($args);

    my $ct = ($args->{code_type} //= 'validator');
    if ($ct ne 'validator') {
        $self->_die({}, "code_type currently can only be 'validator'");
    }
    my $rt = ($args->{return_type} //= 'bool');
    if ($rt !~ /\A(bool|str|full)\z/) {
        $self->_die({}, "Invalid value for return_type, ".
                        "use bool|str|full");
    }
    $args->{var_prefix} //= "_sahv_";
    $args->{sub_prefix} //= "_sahs_";
    $args->{data_term}  //= $self->var_sigil . $args->{data_name};
    $args->{data_term_is_lvalue} //= 1;
    $args->{comment} //= 1;
    $args->{err_term}   //= $self->var_sigil . "err_$args->{data_name}";
}

sub comment {
    my ($self, $cd, @args) = @_;
    return '' unless $cd->{args}{comment};

    my $content = join("", @args);
    $content =~ s/\n+/ /g;

    my $style = $self->comment_style;
    if ($style eq 'shell') {
        return join("", "# ", $content, "\n");
    } elsif ($style eq 'cpp') {
        return join("", "// ", $content, "\n");
    } elsif ($style eq 'c') {
        return join("", "/* ", $content, '*/');
    } elsif ($style eq 'ini') {
        return join("", "; ", $content, "\n");
    } else {
        $self->_die($cd, "BUG: Unknown comment style: $style");
    }
}

# enclose expression with parentheses, unless it already is
sub enclose_paren {
    my ($self, $expr, $force) = @_;
    if ($expr =~ /\A(\s*)(\(.+\)\s*)\z/os) {
        return $expr if !$force;
        return "$1($2)";
    } else {
        $expr =~ /\A(\s*)(.*)/os;
        return "$1($2)";
    }
}

sub add_module {
    my ($self, $cd, $name) = @_;

    return if $name ~~ $cd->{modules};
    push @{ $cd->{modules} }, $name;
}

sub add_var {
    my ($self, $cd, $name, $value) = @_;

    return if exists $cd->{vars}{$name};
    $cd->{vars}{$name} = $value;
}

sub before_compile {
    my ($self, $cd) = @_;

    if ($cd->{args}{data_term_is_lvalue}) {
        $cd->{data_term} = $cd->{args}{data_term};
    } else {
        my $v = $cd->{args}{var_prefix} . $cd->{args}{data_name};
        push @{ $cd->{vars} }, $v; # XXX unless already there
        $cd->{data_term} = $self->var_sigil . $v;
        # XXX perl specific!
        push @{ $cd->{ccls} }, ["(local($cd->{data_term} = $cd->{args}{data_term}), 1)"];
    }
}

sub before_clause {
    my ($self, $cd) = @_;

    $self->_die($cd, "Sorry, .op + .is_expr not yet supported ".
                    "(found in clause $cd->{clause})")
        if $cd->{cl_is_expr} && $cd->{cl_op};

    if ($cd->{args}{debug}) {
        state $json = do {
            require JSON;
            JSON->new->allow_nonref;
        };
        my $clset = $cd->{clset};
        my $cl    = $cd->{clause};
        my $res   = $json->encode({
            map { $_ => $clset->{$_}}
                grep {/\A\Q$cl\E(?:\.|\z)/}
                    keys %$clset });
        $res =~ s/\n+/ /g;
        # a one-line dump of the clause, suitable for putting in generated
        # code's comment
        $cd->{_debug_ccl_note} = "clause: $res";
    } else {
        $cd->{_debug_ccl_note} = "clause: $cd->{clause}";
    }

    $cd->{save_ccls} = $cd->{ccls};
    $cd->{ccls} = [];
}

sub after_clause {
    my ($self, $cd) = @_;

    if ($cd->{args}{debug}) {
        delete $cd->{_debug_ccl_note};
    }

    if (@{ $cd->{ccls} }) {
        push @{$cd->{save_ccls}}, {
            ccl       => $self->join_ccls($cd, $cd->{ccls}, {op=>$cd->{cl_op}}),
            err_level => $cd->{clset}{"$cd->{clause}.err_level"} // "error",
        };
    }
    $cd->{ccls} = delete($cd->{save_ccls});
}

sub after_all_clauses {
    my ($self, $cd) = @_;

    # simply join them together with &&

    $cd->{result} = $self->join_ccls($cd, $cd->{ccls}, {err_msg => ''});
}

1;
# ABSTRACT: Base class for programming language compilers

=for Pod::Coverage ^(after_.+|before_.+|add_module|add_var|check_compile_args|enclose_paren|init_cd)$

=head1 SYNOPSIS


=head1 DESCRIPTION

This class is derived from L<Data::Sah::Compiler>. It is used as base class for
compilers which compile schemas into code (usually a validator) in programming
language targets, like L<Data::Sah::Compiler::perl> and
L<Data::Sah::Compiler::js>. The generated validator code by the compiler will be
able to validate data according to the source schema, usually without requiring
Data::Sah anymore.

Aside from Perl and JavaScript, this base class is also suitable for generating
validators in other procedural languages, like PHP, Python, and Ruby. See CPAN
if compilers for those languages exist.

Compilers using this base class are usually flexible in the kind of code they
produce:

=over 4

=item * configurable validator return type

Can generate validator that returns a simple bool result, str, or full data
structure.

=item * configurable data term

For flexibility in combining the validator code with other code, e.g. in sub
wrapper (one such application is in L<Perinci::Sub::Wrapper>).

=back

Planned future features include:

=over 4

=item * generating other kinds of code (aside from validators)

Perhaps data compliance measurer, data transformer, or whatever.

=back


=head1 ATTRIBUTES

These usually need not be set/changed by users.

=head2 comment_style => STR

Specify how comments are written in the target language. Either 'cpp' (C<//
comment>), 'shell' (C<# comment>), 'c' (C</* comment */>), or 'ini' (C<;
comment>). Each programming language subclass will set this, for example, the
perl compiler sets this to 'shell' while js sets this to 'cpp'.

=head2 var_sigil => STR

To be moved to Perlish.


=head1 METHODS

=head2 new() => OBJ

=head2 $c->compile(%args) => RESULT

Aside from base class' arguments, this class supports these arguments (suffix
C<*> denotes required argument):

=over 4

=item * data_term => STR

A variable name or an expression in the target language that contains the data,
defaults to I<var_sigil> + C<name> if not specified.

=item * data_term_is_lvalue => BOOL (default: 1)

Whether C<data_term> can be assigned to.

=item * err_term => STR

A variable name or lvalue expression to store error message(s), defaults to
I<var_sigil> + C<err_NAME> (e.g. C<$err_data> in the Perl compiler).

=item * var_prefix => STR (default: _sahv_)

Prefix for variables declared by generated code.

=item * sub_prefix => STR (default: _sahs_)

Prefix for subroutines declared by generated code.

=item * code_type => STR (default: validator)

The kind of code to generate. For now the only valid (and default) value is
'validator'. Compiler can perhaps generate other kinds of code in the future.

=item * return_type => STR (default: bool)

Specify what kind of return value the generated code should produce. Either
C<bool>, C<str>, or C<full>.

C<bool> means generated validator code should just return true/false depending
on whether validation succeeds/fails.

C<str> means validation should return an error message string (the first one
encountered) if validation fails and an empty string/undef if validation
succeeds.

C<full> means validation should return a full data structure. From this
structure you can check whether validation succeeds, retrieve all the collected
errors/warnings, etc.

=item * debug => BOOL (default: 0)

This is a general debugging option which should turn on all debugging-related
options, e.g. produce more comments in the generated code, etc. Each compiler
might have more specific debugging options.

=item * debug_log => BOOL (default: 0)

Whether to add logging to generated code.

=item * comment => BOOL (default: 1)

If set to false, generated code will be devoid of comments.

=back

=head3 Compilation data

This subclass adds the following compilation data (C<$cd>).

Keys which contain compilation state:

=over 4

=item * B<data_term> => ARRAY

Input data term. Set to C<< $cd->{args}{data_term} >> or a temporary variable
(if C<< $cd->{args}{data_term_is_lvalue} >> is false). Hooks should use this
instead of C<< $cd->{args}{data_term} >> directly, because aside from the
aforementioned temporary variable, data term can also change, for example if
C<default.temp> or C<prefilters.temp> attribute is set, where generated code
will operate on another temporary variable to avoid modifying the original data.
Or when C<.input> attribute is set, where generated code will operate on
variable other than data.

=back

Keys which contain compilation result:

=over 4

=item * B<modules> => ARRAY

List of module names that are required by the code, e.g. C<["Scalar::Utils",
"List::Util"]>).

=item * B<subs> => ARRAY

Contains pairs of subroutine names and definition code string, e.g. C<< [
[_sahs_zero => 'sub _sahs_zero { $_[0] == 0 }'], [_sahs_nonzero => 'sub
_sah_s_nonzero { $_[0] != 0 }'] ] >>. For flexibility, you'll need to do this
bit of arranging yourself to get the final usable code you can compile in your
chosen programming language.

=item * B<vars> => ARRAY ?

=back

=head2 $c->comment($cd, @args) => STR

Generate a comment. For example, in perl compiler:

 $c->comment($cd, "123"); # -> "# 123\n"

Will return an empty string if compile argument C<comment> is set to false.

=cut
