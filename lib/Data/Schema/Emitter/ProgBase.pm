package Data::Schema::Emitter::ProgBase;
# ABSTRACT: Base class for DS programming language emitters

use Any::Moose;
extends 'Data::Schema::Emitter::Base';
use Log::Any qw($log);
use Digest::MD5 qw(md5_hex);

has sub_vars_stack => (is => 'rw', default => sub { [] });
has result_stack => (is => 'rw', default => sub { [] });
has indent_level => (is => 'rw', default => 0);

sub on_start {
    my ($self, %args) = @_;
    my $res = $self->SUPER::on_start(%args);
    return $res if ref($res) eq 'HASH' && $res->{SKIP_EMIT};

    $self->states->{defined_subs} //= {};
    $self->states->{loaded_modules} //= {};

    my $subname = $self->subname($args{schema});
    return {SKIP_EMIT => 1} if $self->states->{defined_subs}{$subname};

    # reset list of sub vars
    push @{ $self->sub_vars_stack }, $self->states->{sub_vars};
    $self->states->{sub_vars} = {};

    my $s = $args{schema};
    my $x = $self->dump($s->{attr_hashes});
    $x =~ s/\n.*//s;
    $x = substr($x, 0, 76) . ' ...' if length($x) > 80;
    $self->comment("schema $s->{type} ", $x);
};

before on_end => sub {
    my ($self, %args) = @_;
    $self->states->{sub_vars} = pop @{ $self->sub_vars_stack };
};

sub before_attr {
    my ($self, %args) = @_;
    my $attr = $args{attr};
    my $x = $self->dump($attr->{value});
    $x =~ s/\n.*//s;
    $x = substr($x, 0, 76) . ' ...' if length($x) > 80;
    $self->comment("attr $attr->{name} #$attr->{i}", (defined($attr->{value}) ? ": $x" : ""));
}

sub after_attr {
    my ($self, %args) = @_;
    my $attr = $args{attr};
    my $res = $args{attr_res};
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
                   $self->config->sub_prefix,
                   $self->states->{subnames}{$type}{$key},
                   $type);
}

sub define_sub {
    my ($self, $name, $content) = @_;
    $self->states->{defined_subs}{$name} = 1;
    # child should do the actual code to define sub after this.
}

sub load_module {
    my ($self, $name) = @_;
    $self->states->{loaded_modules}{$name} = 1;
    # child should do the actual code to load module after this.
}

sub var {
    # declare var. child should override this.
}

sub dump {
    # child should override this with method to dump data structures
    # on a single line.
}

sub indent {
    my ($self) = @_;
    " " x ($self->config->indent * $self->indent_level);
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
    my $style = $self->config->comment_style;

    if ($style eq 'shell') {
        $self->line("# ", @args);
    } elsif ($style eq 'c++') {
        $self->line("// ", @args);
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
forget_defined_subs() before you emit().

=cut

sub forget_defined {
    my ($self) = @_;
    $self->states->{defined_subs} = {};
    $self->states->{loaded_modules} = {};
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
