package Data::Sah::Compiler::BaseProg;

use 5.010;
use Moo;
extends 'Data::Sah::Compiler::BaseCompiler';
use Log::Any qw($log);

# VERSION

#use Digest::MD5 qw(md5_hex);

# human compiler, to produce error messages
has hc => (
    is => 'rw',
    lazy => 1,
    default => sub {
        Data::Sah::Compiler::human->new;
    },
);

# subclass should provide a default, choices: 'shell', 'c', 'ini', 'cpp'
has comment_style => (is => 'rw');

has var_sigil => (is => 'rw', default => sub {''});

sub compile {
    my ($self, %args) = @_;

    my $ct = $args{code_type} // 'validator';
    if ($ct ne 'validator') {
        $self->_die({}, "code_type currently can only be 'validator'");
    }
    my $vrt = $args{validator_return_type} // 'bool';
    if ($vrt !~ /\A(bool|str|full)\z/) {
        $self->_die({}, "Invalid value for validator_return_type, ".
                        "use bool|str|full");
    }
    $self->_check_compile_args(\%args);
    $args{var_prefix} //= "_sahv_";
    $args{sub_prefix} //= "_sahs_";
    for my $in (@{ $args{inputs} }) {
        $in->{term}   //= $in->{name};
        $in->{lvalue} //= 1;
    }
    $self->SUPER::compile(%args);
}

sub comment {
    my ($self, $cd, @args) = @_;
    my $style = $self->comment_style;

    if ($style eq 'shell') {
        $self->line($cd, "# ", @args);
    } elsif ($style eq 'cpp') {
        $self->line($cd, "// ", @args);
    } elsif ($style eq 'c') {
        $self->line($cd, "/* ", @args, '*/');
    } elsif ($style eq 'ini') {
        $self->line($cd, "; ", @args);
    } else {
        $self->_die($cd, "BUG: Unknown comment style: $style");
    }
    $self;
}

sub before_input {
    my ($self, $cd) = @_;
    my $in = $cd->{input};

    $cd->{exprs} = [];
    if ($in->{lvalue}) {
        $cd->{in_term} = $self->var_sigil . $in->{term};
    } else {
        my $v = $cd->{args}{var_prefix} . $in->{name};
        push @{ $cd->{vars} }, $v;
        $cd->{in_term} = $self->var_sigil . $v;
        push @{ $cd->{exprs} }, "(local($cd->{in_term} = $in->{term}), 1)";
    }
}

# a common routine to handle a normal clause
sub handle_clause {
    my ($self, $cd, %args) = @_;

    my @caller = caller(0);
    $self->_die($cd, "BUG: on_term not supplied by ".$caller[3])
        unless $args{on_term};

    my $clause = $cd->{clause};
    my $th     = $cd->{th};

    $self->_die($cd, "Sorry, .is_multi + .is_expr not yet supported ".
                    "(found in clause $clause)")
        if $cd->{cl_is_expr} && $cd->{cl_is_multi};

    $self->_die($cd, "$clause.is_multi set, but $clause value not an array")
        if $cd->{cl_is_multi} && ref($cd->{cl_term}) != 'ARRAY';
    my $terms = $cd->{cl_is_multi} ? $cd->{cl_term} : [$cd->{cl_term}];
    my $oexprs = $cd->{exprs};
    $cd->{exprs} = [];
    for my $term (@$terms) {
        local $cd->{cl_term} = $term;
        $args{on_term}->($self, $cd);
    }
    if (@{ $cd->{exprs} }) {
        push @$oexprs, $self->join_exprs(
            $cd->{exprs},
            $cd->{cset}{"$clause.min_ok"},
            $cd->{cset}{"$clause.max_ok"},
            $cd->{cset}{"$clause.min_nok"},
            $cd->{cset}{"$clause.max_nok"},
        );
    }
    $cd->{exprs} = $oexprs;

    delete $cd->{ucset}{"$clause.min_ok"};
    delete $cd->{ucset}{"$clause.max_ok"};
    delete $cd->{ucset}{"$clause.min_nok"};
    delete $cd->{ucset}{"$clause.max_nok"};
}

sub after_clause_set {
    my ($self, $cd) = @_;
    my $jexpr = $self->join_exprs(
        $cd->{exprs},
        $cd->{cset}{".min_ok"},
        $cd->{cset}{".max_ok"},
        $cd->{cset}{".min_nok"},
        $cd->{cset}{".max_nok"},
    );
    $cd->{exprs} = [$jexpr] if length($jexpr);
    delete $cd->{ucset}{".min_ok"};
    delete $cd->{ucset}{".max_ok"};
    delete $cd->{ucset}{".min_nok"};
    delete $cd->{ucset}{".max_nok"};
}


#sub before_all_clauses {
#    my (%args) = @_;
#    my $cdata = $args{cdata};
#
#    if (ref($th) eq 'HASH') {
#        # type is defined by schema
#        $log->tracef("Type %s is defined by schema %s", $tn, $th);
#        $self->_die($cd, "Recursive definition: " .
#                        join(" -> ", @{$self->state->{met_types}}) .
#                            " -> $tn")
#            if grep { $_ eq $tn } @{$self->state->{met_types}};
#        push @{ $self->state->{met_types} }, $tn;
#        $self->_compile(
#            inputs => [schema => {
#                type => $th->{type},
#                clause_sets => [@{ $th->{clause_sets} },
#                                @{ $nschema->{clause_sets} }],
#                def => $th->{def} }],
#        );
#        goto FINISH_INPUT;
#    }
#}

1;
# ABSTRACT: Base class for programming language compilers

=head1 SYNOPSIS


=head1 DESCRIPTION

This class is derived from L<Data::Sah::Compiler::BaseCompiler>. It is used as
base class for compilers which compile schemas into code (usually a validator)
in programming language targets, like L<Data::Sah::Compiler::perl> and
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


=head1 METHODS

=head2 new() => OBJ

=head2 $c->compile(%args) => RESULT

Aside from BaseCompiler's arguments, this class supports these arguments (suffix
C<*> denotes required argument):

=over 4

=item * inputs => ARRAY

This extends L<Data::Sah::Compiler::BaseCompiler>'s C<inputs>.

Each input must also contain these keys: C<term> (string, a variable name or an
expression in the target language that contains the data, default to C<name> if
not specified), C<lvalue> (bool, whether C<term> can be assigned to, default 1).

=item * var_prefix => STR (default: _sahv_)

Prefix for variables declared by generated code.

=item * sub_prefix => STR (default: _sahs_)

Prefix for subroutines declared by generated code.

=item * code_type => STR (default: validator)

The kind of code to generate. For now the only valid (and default) value is
'validator'. Compiler can perhaps generate other kinds of code in the future.

=item * validator_return_type => STR (default: bool)

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

=item * load_modules => BOOL (default: 1)

Whether to load modules required by validator code. If set to 0, you have to
make sure that the required modules are loaded prior to running the code (see
B<Return> below).

=back

=head3 Compilation data

This subclass adds the following compilation data (C<$cd>).

Keys which contain compilation state:

=over 4

=item * B<in_term> => ARRAY

Input (data) term. Set to C<< $cd->{input}{term} >> or a temporary variable (if
C<< $cd->{input}{lvalue} >> is false). Hooks should use C<in_term> instead,
because aside from the mentioned temporary variable due to not being an lvalue,
data term can also change, for example if C<default.temp> or C<prefilters.temp>
attribute is set, where generated code will operate on another temporary
variable to avoid modifying the original data. Or when C<.input> attribute is
set, where generated code will operate on variable other than data.

=item * B<exprs> => ARRAY

Expressions that are collected during processing of a clause set. At the end of
clause set, they are joined together.

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

=head2 $c->comment($cd, @arg)

Append a comment line to C<< $cd->{result} >>. Used by compiler; users normally
do not need this. Example:

 $c->comment($cd, 'this is a comment', ', ', 'and this one too');

When C<comment_style> is C<shell> this line will be added:

 # this is a comment, and this one too

=head2 $c->join_exprs(\@exprs, $min_ok, $max_ok) => STR

=cut
