package Data::Sah::Compiler::BaseProg;

use 5.010;
use Moo;
extends 'Data::Sah::Compiler::BaseCompiler';
use Log::Any qw($log);

# VERSION

#use Digest::MD5 qw(md5_hex);

# subclass should override this
sub indent_width { 0 }

# subclass should override this
sub comment_style { undef }

sub compile {
    my ($self, %args) = @_;

    my $ct = $args{code_type} // 'validator';
    if ($ct ne 'validator') {
        $self->_die("code_type currently can only be 'validator'");
    }
    my $vrt = $args{validator_return_type} // 'bool';
    if ($vrt !~ /\A(bool|str|full)\z/) {
        $self->_die("Invalid value for validator_return_type, ".
                        "use bool|str|full");
    }
    $self->SUPER::compile(%args);
}

#    $vdump =~ s/\n.*//s;
#    $vdump = substr($vdump, 0, 76) . ' ...' if length($vdump) > 80;

sub line {
    my ($self, $cdata, @args) = @_;
    push @{ $self->result }, join("", $cdata->{indent}, @args);
    $self;
}

sub comment {
    my ($self, $cdata, @args) = @_;
    my $style = $self->comment_style;

    if ($style eq 'shell') {
        $self->line($cdata, "# ", @args);
    } elsif ($style eq 'c++') {
        $self->line($cdata, "// ", @args);
    } elsif ($style eq 'c') {
        $self->line($cdata, "/* ", @args, '*/');
    } elsif ($style eq 'ini') {
        $self->line($cdata, "; ", @args);
    } else {
        $self->_die("BUG: Unknown comment style: $style");
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
validators in programming language targets, like L<Data::Sah::Compiler::perl>
and L<Data::Sah::Compiler::js>. The generated code by the compiler will be able
to validate data according to the source schema.

Aside from Perl and JavaScript, this base class is also suitable for generating
validators in other procedural languages, like PHP, Python, and Ruby. See CPAN
if compilers for those languages exist.

Compilers using this base class are usually flexible in the kind of code they
produce:

=over 4

=item * configurable validator form

Simple schema can be compiled into validator in the form of a single expression
(e.g. '$data >= 1 && $data <= 10') for the least amount of overhead. More
complex schema can be compiled into full subroutines.

=item * configurable validator return type

Can generate validator that returns a simple bool result, str, or full obj.

=item * configurable data term

For flexibility in combining the validator code with other code, e.g. in sub
wrapper (one such application is in L<Perinci::Sub::Wrapper>).

=back

Planned future features include:

=over 4

=item * generating other kinds of code (aside from validators)

Perhaps data compliance measurer, data transformer, or whatever.

=back

This class is derived from L<Data::Sah::Compiler::BaseCompiler>.


=head1 (CLASS INSTANCE) ATTRIBUTES

=head2 sub_prefix => STR

Prefix to use for generated subroutines. Default to 'sah_'.


=head1 CLASS ATTRIBUTES

=head2 indent_width => INT

Specify how many spaces indents in the target language are. Each programming
language subclass will set this, for example the perl compiler sets this to 4
while js sets this to 2.

=head2 comment_style => STR

Specify how comments are written in the target language. Either 'c++' (C<//
comment>), 'shell' (C<# comment>), 'c' (C</* comment */>), or 'ini' (C<;
comment>). Each programming language subclass will set this, for example, the
perl compiler sets this to 'shell' while js sets this to 'c++'.


=head1 METHODS

=head2 new() => OBJ

=head2 $c->compile(%args) => HASH

Aside from BaseCompiler's arguments, this class supports these arguments (suffix
C<*> denotes required argument):

=over 4

=item * inputs => ARRAY

This extends L<Data::Sah::Compiler::BaseCompiler>'s C<inputs>.

Each input must also contain these keys: C<term> (string, a variable name or an
expression in the target language that contains the data), C<lvalue> (whether
C<term> can be assigned to),

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

B<Return>. Aside from B<result> key which is the final code string, there are
also B<modules> (an arrayref) which is a list of module names that are required
by the code (e.g. C<["Scalar::Utils", "List::Util"]>), B<subs> (an arrayref)
which contains subroutine name and definition code string, if any (e.g.
C<[sah_zero => 'sub sah_zero { $_[0] == 0 }', sah_nonzero => 'sub sah_nonzero {
$_[0] != 0 }']>. For flexibility, you'll need to do this bit of arranging
yourself to get the final usable code you can compile in your chosen programming
language.


=head1 SUBCLASSING

TBD

=cut
