package Data::Sah::Compiler::BaseProg;

use 5.010;
use Moo;
extends 'Data::Sah::Compiler::BaseCompiler';
use Log::Any qw($log);

has expr_compiler => (is => 'rw');

#use Digest::MD5 qw(md5_hex);

sub compile {
    my ($self, %args) = @_;
    $self->SUPER::compile(%args);
}

#    $vdump =~ s/\n.*//s;
#    $vdump = substr($vdump, 0, 76) . ' ...' if length($vdump) > 80;

sub inc_indent {
    my ($self) = @_;
    $self->indent_level($self->indent_level+1);
    $self;
}

sub dec_indent {
    my ($self) = @_;
    die "Bug: should not decrease indent level when it is 0"
        unless $self->indent_level >= 0;
    $self->indent_level($self->indent_level-1);
    $self;
}

sub line {
    my ($self, @args) = @_;
    push @{ $self->result }, join("", $self->indent, @args);
    $self;
}

sub comment {
    my ($self, @args) = @_;
    my $style = $self->comment_style;

    if ($style eq 'shell') {
        $self->line("# ", @args);
    } elsif ($style eq 'c++') {
        $self->line("// ", @args);
    } elsif ($style eq 'c') {
        $self->line("/* ", @args, '*/');
    } elsif ($style eq 'ini') {
        $self->line("; ", @args);
    } else {
        $self->_die("Unknown comment style: $style");
    }
    $self;
}

# XXX not adjusted yet
#sub before_all_clauses {
#    my (%args) = @_;
#    my $cdata = $args{cdata};
#
#    if (ref($th) eq 'HASH') {
#        # type is defined by schema
#        $log->tracef("Type %s is defined by schema %s", $tn, $th);
#        $self->_die("Recursive definition: " .
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

This class is used as base class for compilers which compile schemas into
programming language targets, like L<Data::Sah::Compiler::perl> and
L<Data::Sah::Compiler::js>. This class is also suitable for other procedural
languages, like PHP, Python, Ruby. See CPAN if compilers for those languages
exist.

Below are some features of this base class: Support for compiling Sah schemas
into expression, statements, or subroutines. Configurable code result type
(bool, str, or obj). Configurable indent level and comment-style according to
target language. Configurable data term.

This class is derived from L<Data::Sah::Compiler::BaseCompiler>.


=head1 METHODS

=head2 new() => OBJ

=head2 $c->compile(%args) => RESULT

Aside from BaseCompiler's arguments, this class supports these arguments:

=over 4

=item * indent_level => INT

Specify how many spaces indents in the target language are. Normally, each
programming language subclass will set this so you don't have to do this
manually. For example, the perl compiler sets this to 4 while js sets this to 2.

=item * comment_style => STR

Specify how comments are written in the target language. Either 'c++' (C<//
comment>), 'shell' (C<# comment>), 'c' (C</* comment */>), or 'ini' (C<;
comment>). Normally, each programming language subclass will set this so you
don't have to do this manually. For example, the perl compiler sets this to
'shell' while js sets this to 'c++'.

=item * code_type => STR

Specify what kind of code the compiler should produce. Either 'expr',
'statements', or 'sub'. Defaults to 'sub'.

'expr' means an expression should be generated. For example, perl compiler will
compile the schema ['str*', min_len=>8] into something like (if C<result_type>
is 'bool'):

 (!ref($data) && defined($data) && length($data))

or (if C<result_type> is 'str'):

 (ref($data) ? "Data not a string" :
     !defined($data) ? "Data required" :
         length($data) < 8 ? "Length of data minimum 8")

If C<code_type> is 'statements', the result might be something like (if
C<result_type> is 'bool'):

 return 0 if ref($data);
 return 0 unless defined($data);
 return 0 unless length($data) >= 8;
 return 1;

And if C<code_type> is 'sub', the result might look like:

 sub sah_str1 {
     my ($data) = @_;
     return 0 if ref($data);
     return 0 unless defined($data);
     return 0 unless length($data) >= 8;
     return 1;
 }

Different code_type can be useful in different situation. For very simple
schemas, outputing an expression will produce the most compact and low-overhead
code which can also be combined in more ways with other external code. However,
not all schemas can be output as simple expression, especially more complex
ones.

If code_type request cannot be fulfilled, code will be output in another
code_type as the compiler sees fit.

=item * result_type => STR

Specify what kind of result the resulting code should produce. Either 'bool',
'str', or 'obj'. Default is 'obj'.

'bool' means code should just return 1/0 depending on whether validation
succeeds/fails.

'str' means validation should return an error message string (the first one
encountered) if validation fails and an empty string/undef if validation
succeeds.

'obj' means validation should return a full result object (see
L<Data::Sah::Result>). From this object you can check whether validation
succeeds, retrieve all the collected errors/warnings, etc.

Limitation: If If C<code_type> is 'expr', C<result_type> usually can only be
'bool' or 'str'.

=item * sub_prefix => STR

Prefix to use for generated subroutines. Default to 'sah_'.

=back

About result: Result is a hash containing these keys: C<code_type> is the final
code type, B<result_type> is the final result type, B<code> is a string
containing the final code, B<requires> which is a string containing require/use
statements which is required for the code to run, B<subs> is an array of string
containing zero or more subroutine definitions. So even if B<code_type> is an
expression, it might need some require/use lines or subroutine definition.

=cut
