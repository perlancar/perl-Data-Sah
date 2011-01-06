package Data::Sah::Emitter::ProgBase;
# ABSTRACT: Base class for programming language emitters

use 5.010;
use Any::Moose;
extends 'Data::Sah::Emitter::Base';
use Log::Any qw($log);

use Digest::MD5 qw(md5_hex);

=for Pod::Coverage .*

=head1 ATTRIBUTES

=head2 data_term

=cut

has data_term        => (is => 'rw', default => '$data');

=head2 emit_form => STR

Valid values: 'expr', 'stmts', 'sub'. Default is 'sub'.

'expr' means a single expression will be returned (which is not always possible
except for simple schemas), for example 'str*' will be emitted by Perl emitter
as something like:

 defined($data) && !ref($data)

'stmts' means emitter should return a list of one or more statements. For
example, [str=>{minlen=>4, maxlen=>8}] will be emitted as something like:

 {
     if (!defined($data)) { last }
     unless (ref($data)) { warn "Data must be a string"; last }
     unless (length($data)>=4) { warn "Data must be at least 4 chars long" }
     unless (length($data)>=8) { warn "Data must be at most 8 chars long" }
 }

'sub' means emitter should return a subroutine. For example, the previous schema
will be emitted as something like:

 sub sah_str1 {
     my ($data) = @_;
     my $has_err;
     if (!defined($data)) { return 1 }
     unless (ref($data)) { warn "Data must be a string"; return }
     unless (length($data)>=4) { warn "Data must be at least 4 chars long"; $has_err++ }
     unless (length($data)>=8) { warn "Data must be at most 8 chars long"; $has_err++ }
     return !$has_err;
 }

=cut

# IN SUPERCLASS

=head2 vresult_form => STR

What kind of validation result should the emitted code return? Valid values:
'bool', 'str', 'full'. Default is 'full'.

'bool' means validation should just return 1/0 depending on whether validation
succeeds/fails. If C<emit_form> is 'expr', C<vresult_form> usually can only be
'bool'.dd

'str' means validation should return an error message string (the first one
encountered) if validation fails and an empty string/undef if validation
succeeds.

'full' means validation should return a full result structure/object. It can
contain all errors and warnings encountered during validation, etc.

Each emitter might add other possibilities.

=cut

has vresult_form     => (is => 'rw', default => 'sub');
has sub_prefix       => (is => 'rw');

# either 'shell' (# blah) or 'c' (/* blah */) or 'c++' (// blah) or ini (; blah)
has comment_style    => (is => 'rw');

has emitted_var_defs => (is => 'rw', default => sub { {} });
has emitted_var_defs_stack => (is => 'rw', default => sub { [] });
has emitted_sub_defs => (is => 'rw', default => sub { {} });
has emitted_uses     => (is => 'rw', default => sub { {} });
has indent_size      => (is => 'rw');
has indent_level     => (is => 'rw', default => 0);
has indent_level_stack => (is => 'rw', default => sub { [] });
has expr_compiler    => (is => 'rw');
has sub_defs         => (is => 'rw', default => sub { [] });
has current_subname_stack => (is => 'rw', default => sub { [] });

=head1 METHODS

=cut

# define_sub* are safe to be called anytime, they won't jumble 'result' and store
# the resulting sub def in sub_defs.

sub BUILD {
    my ($self, @args) = @_;
    $self->emit_form('sub')     unless defined($self->emit_form);
}

sub define_sub_start {
    my ($self, $subname, $comment) = @_;

    push @{ $self->current_subname_stack }, $subname;

    push @{ $self->emitted_var_defs_stack }, $self->emitted_var_defs;
    $self->emitted_var_defs({});
    push @{ $self->result_stack }, $self->result;
    $self->result([]);
    push @{ $self->indent_level_stack }, $self->indent_level;
    $self->indent_level(0);
    $self->comment($comment) if $comment;
}

sub define_sub_end {
    my ($self) = @_;

    my $subname = pop(@{ $self->current_subname_stack });
    push @{ $self->sub_defs }, $self->result
        unless $self->emitted_var_defs->{$subname}++;

    $self->indent_level(pop @{ $self->indent_level_stack });
    $self->result(pop @{ $self->result_stack });
    $self->emitted_var_defs(pop @{ $self->emitted_var_defs_stack });
}

sub on_start {
    my ($self, %args) = @_;
    my $res = $self->SUPER::on_start(%args);
    return $res if ref($res) eq 'HASH' && $res->{SKIP_EMIT};

    my $subname = $self->subname($args{schema});
    return {SKIP_EMIT => 1} if $self->emitted_sub_defs->{$subname};

    my $s = $args{schema};
    my $x = $self->dump($s->{clause_sets});
    $x = substr($x, 0, 76) . ' ...' if length($x) > 80;
    $self->define_sub_start($subname, "schema $s->{type} $x");
}

before on_end => sub {
    my ($self, %args) = @_;
    $self->define_sub_end;
    $self->result([]);

    #use Data::Dump; dd $self->sub_defs;
    #dd $self->emitted_sub_defs;

    $self->preamble();

    while (my $def = shift @{ $self->sub_defs }) {
        push @{ $self->result }, @$def, "\n";
    }
};

=head2 before_clause

Make $clause->{value} as a term in code (e.g. in Perl, [1, 2, 3] becomes '[1, 2,
3]' Perl code).

If clause does not contain expression (in 'expr' attribute), set
$clause->{value} to $self->dump($clause->{value}). Otherwise, call
$self->on_expr(). The on_expr() method is expected to set $clause->{value}
appropriately.

=cut

sub before_clause {
    my ($self, %args) = @_;
    my $clause = $args{clause};

    my ($n, $v) = ($clause->{name}, $clause->{value});
    my $vdump = $self->dump($v);
    $vdump =~ s/\n.*//s;
    $vdump = substr($vdump, 0, 76) . ' ...' if length($vdump) > 80;
    my $expr0 = $clause->{attrs}{expr};
    $self->comment("clause $n",
                   ($clause->{cs_idx} > 0 ? "#$clause->{cs_idx}" : ""),
                   (defined($expr0) ?
                        " = $expr0" :
                            defined($v) ? ": $vdump" : ""));
    my $expr = $n eq 'check' ? $v : $expr0;
    if (defined $expr) {
        $self->on_expr(%args);
    } else {
        $clause->{raw_value} = $clause->{value};
        $clause->{value} = $self->dump($clause->{value});
    }
    {};
}

sub after_clause {
    my ($self, %args) = @_;
    my $clause = $args{clause};
    my $res = $args{clause_res};
    $self->line;
}

# ---

sub subname {
    my ($self, $schema, $normalized) = @_;
    my $main = $self->main;

    unless ($normalized) {
        my $res = $main->normalize_schema($schema);
        die "Can't normalize schema: $res" unless ref($res);
        $schema = $res;
    }

    my $key = join("-",
                   md5_hex($main->_dump($schema)),
                   #md5_hex($main->_dump($self->config))
               );

    #$log->tracef("subname(%s): %s -> %s", $schema, $main->_dump($schema), $key);

    my $type = $schema->{type};
    $self->states->{subnames} //= {};
    $self->states->{subnames}{$type} //= {};
    $self->states->{subnames}{$type}{$key} //= 0 + keys(%{ $self->states->{subnames}{$type} });
    #$log->tracef("subnames = %s", $self->states->{subnames});
    return sprintf("%scs%d_%s",
                   $self->sub_prefix,
                   $self->states->{subnames}{$type}{$key},
                   $type);
}

sub load_module {
    my ($self, $name) = @_;
    return if $self->states->{loaded_modules}{$name}++;
    # child should do the actual code to load module after this.
}

sub var {
    # define and/or set a subroutine level variable. child classes should
    # implement this.
}

sub dump {
    # child should override this with method to dump data structures on a single
    # line.
}

sub preamble {
    # child should override this to emit stuffs at the beginning before
    # subroutine definitions.
}

sub indent {
    my ($self) = @_;
    " " x ($self->indent_size * $self->indent_level);
}

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
        die "Unknown comment style: $style";
    }
    $self;
}

=head1 METHODS

=head2 forget_defined()

Normally emit() will remember every emitted definition of subroutine and every
loaded modules. So the second time you call emit(), they will not be
defined/mentioned again. This default behaviour is appropriate when you eval()
each output of emit(), becauuse it avoids duplicate definition.

But sometimes you want emit() to output every required bit. In that case, call
forget_defined() before you emit().

=cut

sub forget_defined {
    my ($self) = @_;
    $self->states->{emitted_sub_defs} = {};
    $self->states->{emitted_uses}     = {};
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
