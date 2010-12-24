package Data::Sah::Emitter::Perl::Expr;

# temporary/stub

use 5.010;
use Any::Moose;
with 'Data::Expr::InterpreterRole';

# reference to main Data::Expr object
has main => (is => 'rw');

use boolean ':all';
use Scalar::Util 'looks_like_number';
use List::Util 'reduce';
use Data::Dump::OneLine qw(dump_one_line);

my $t_number = looks_like_number("Inf"+0) | looks_like_number("NaN"+0) | looks_like_number(1);

sub __isnum {
    my ($a) = @_;
    looks_like_number($a) | $t_number;
}

sub __isstr {
    my ($a) = @_;
    defined($a) && !ref($a) && !__isnum($a);
}

sub __typeof {
    my ($a) = @_;
    if (!defined($a)) {
        return "undef";
    } elsif (ref($a)) {
        return ref($a);
    } elsif (__isnum($a)) {
        if ($a == int($a) && abs($a) <= ~0) {
            return "int";
        } else {
            return "float";
        }
    } else {
        return "str";
    }
}

sub __cmp {
    my ($a, $b) = @_;
    my $ta = __typeof($a);
    my $tb = __typeof($b);

    if (!defined($a) && !defined($b)) {
        return true;
    } elsif (!defined($a) || !defined($b)) {
        return false;
    } elsif (ref($a) && ref($b)) {
        die sprintf("Type mismatch: %s vs %s", __typeof($a), __typeof($b))
            unless ref($a) eq ref($b);
        return dump_one_line($a) eq dump_one_line($b);
    } elsif (ref($a) || ref($b)) {
        die sprintf("Type mismatch: %s vs %s", __typeof($a), __typeof($b));
    } elsif (__isnum($a) && __isnum($b)) {
        return $a == $b;
    } else {
        return $a eq $b;
    }
}

sub __eq {
    my ($a, $b) = @_;
    if (!defined($a) && !defined($b)) {
        return true;
    } elsif (!defined($a) || !defined($b)) {
        return false;
    } elsif (ref($a) && ref($b)) {
        return false unless ref($a) eq ref($b);
        return dump_one_line($a) eq dump_one_line($b);
    } elsif (ref($a) || ref($b)) {
        return false;
    } elsif (__isnum($a) && __isnum($b)) {
        return $a == $b;
    } else {
        return $a eq $b;
    }
}

sub rule_pair {
    my ($self, %args) = @_;
    my $match = $args{match};
    [$match->{key}, $match->{value}];
}

sub rule_or {
    my ($self, %args) = @_;
    my $match = $args{match};
    my $res = shift @{$match->{operand}};
    for my $term (@{$match->{operand}}) {
        my $op = shift @{$match->{op}//=[]};
        if    ($op eq '||') { $res ||= $term }
        elsif ($op eq '//') { $res //= $term }
    }
    $res;
}

sub rule_and {
    my ($self, %args) = @_;
    my $match = $args{match};
    my $res = shift @{$match->{operand}};
    for my $term (@{$match->{operand}}) {
        my $op = shift @{$match->{op}//=[]};
        if    ($op eq '&&') { $res &&= $term }
    }
    $res;
}

sub rule_bit_or {
    my ($self, %args) = @_;
    my $match = $args{match};
    my $res = shift @{$match->{operand}};
    for my $term (@{$match->{operand}}) {
        my $op = shift @{$match->{op}//=[]};
        if    ($op eq '|') { $res = $res+0 | $term }
        elsif ($op eq '^') { $res = $res+0 ^ $term }
    }
    $res;
}

sub rule_bit_and {
    my ($self, %args) = @_;
    my $match = $args{match};
    my $res = shift @{$match->{operand}};
    for my $term (@{$match->{operand}}) {
        my $op = shift @{$match->{op}//=[]};
        if    ($op eq '&') { $res = $res+0 & $term }
    }
    $res;
}

sub rule_equal {
    my ($self, %args) = @_;
    my $match = $args{match};
    my $res = shift @{$match->{operand}};
    for my $term (@{$match->{operand}}) {
        my $op = shift @{$match->{op}//=[]};
        if    ($op eq '==' ) { $res = ($res ==  $term) }
        elsif ($op eq '!=' ) { $res = ($res !=  $term) }
        elsif ($op eq '<=>') { $res = ($res <=> $term) }
        elsif ($op eq 'eq' ) { $res = ($res eq  $term) }
        elsif ($op eq 'ne' ) { $res = ($res ne  $term) }
        elsif ($op eq 'cmp') { $res = ($res cmp $term) }
    }
    $res;
}

sub rule_less_greater {
    my ($self, %args) = @_;
    my $match = $args{match};
    my $res = shift @{$match->{operand}};
    for my $term (@{$match->{operand}}) {
        my $op = shift @{$match->{op}//=[]};
        die "Invalid syntax" unless defined($op);
        if    ($op eq '<' ) { $res = ($res <  $term) }
        elsif ($op eq '<=') { $res = ($res <= $term) }
        elsif ($op eq '>' ) { $res = ($res >  $term) }
        elsif ($op eq '>=') { $res = ($res >= $term) }
        elsif ($op eq 'lt') { $res = ($res lt $term) }
        elsif ($op eq 'gt') { $res = ($res gt $term) }
        elsif ($op eq 'le') { $res = ($res le $term) }
        elsif ($op eq 'ge') { $res = ($res ge $term) }
    }
    $res;
}

sub rule_bit_shift {
    my ($self, %args) = @_;
    my $match = $args{match};
    my $res = shift @{$match->{operand}};
    for my $term (@{$match->{operand}}) {
        my $op = shift @{$match->{op}//=[]};
        if    ($op eq '>>') { $res >>= $term }
        elsif ($op eq '<<') { $res <<= $term }
    }
    $res;
}

sub rule_add {
    my ($self, %args) = @_;
    my $match = $args{match};
    my $res = shift @{$match->{operand}};
    for my $term (@{$match->{operand}}) {
        my $op = shift @{$match->{op}//=[]};
        if    ($op eq '+') { $res += $term }
        elsif ($op eq '-') { $res -= $term }
        elsif ($op eq '.') { $res .= $term }
    }
    $res;
}

sub rule_mult {
    my ($self, %args) = @_;
    my $match = $args{match};
    my $res = shift @{$match->{operand}};
    for my $term (@{$match->{operand}}) {
        my $op = shift @{$match->{op}//=[]};
        if    ($op eq '*') { $res *= $term }
        elsif ($op eq '/') { $res /= $term }
        elsif ($op eq '%') { $res %= $term }
        elsif ($op eq 'x') { $res x= $term }
    }
    $res;
}

sub rule_unary {
    my ($self, %args) = @_;
    my $match = $args{match};
    my $res = $match->{operand};
    if ($match->{op}) {
        for my $op (reverse @{$match->{op}}) {
            if    ($op eq '!') { $res = !$res }
            elsif ($op eq '-') { $res = -$res }
            elsif ($op eq '~') { $res = ~($res+0) }
        }
    }
    $res;
}

sub rule_power {
    my ($self, %args) = @_;
    my $match = $args{match};
    reduce { $b ** $a } reverse @{$match->{operand}};
}

sub rule_subscripting {
    my ($self, %args) = @_;
    my $match = $args{match};
    my $res = shift @{$match->{operand}};
    for my $i (@{$match->{subscript}}) {
        if (ref($res) eq 'ARRAY'  ) { $res = $res->[$i] }
        elsif (ref($res) eq 'HASH') { $res = $res->{$i} }
        else                        { $res = "error: invalid hash subscripting"; last }
    }
    $res;
}

sub rule_array {
    my ($self, %args) = @_;
    my $match = $args{match};
    $match->{element};
}

sub rule_hash {
    my ($self, %args) = @_;
    my $match = $args{match};
    return { map { $_->[0] => $_->[1] } @{ $match->{pair} } }
}

sub rule_undef {
    my ($self, %args) = @_;
    my $match = $args{match};
    undef;
}

sub rule_squotestr {
    my ($self, %args) = @_;
    my $match = $args{match};
    join "", map {
        $_ eq "\\'" ? "'" :
        $_ eq "\\\\" ? "\\" :
        $_
    } @{ $match->{part} };
}

sub rule_dquotestr {
    my ($self, %args) = @_;
    my $match = $args{match};

    #return join(", ", map {"[$_]"} @{$match->{part}});

    join "", map {
        $_ eq "\\'" ? "'" :
        $_ eq "\\\"" ? '"' :
        $_ eq "\\\\" ? "\\" :
        $_ eq "\\\$" ? '$' :
        $_ eq "\\t" ? "\t" :
        $_ eq "\\n" ? "\n" :
        $_ eq "\\f" ? "\f" :
        $_ eq "\\b" ? "\b" :
        $_ eq "\\a" ? "\a" :
        $_ eq "\\e" ? "\e" :
        $_ eq "\\e" ? "\e" :
        /^\\([0-7]{1,3})$/ ? chr(oct($1)) :
        #/^\\x([0-9A-Fa-f]{1,2})$/ ? chr(hex($1)) :
        #/^\\x\{([0-9A-Fa-f]{1,4})\}$/ ? chr(hex($1)) :
        /^\$(\w+)$/ ? $self->vars->{$1} :
        #/^\$\((.+)\)$/ ? $self->vars->{$1} :
        $_ eq "\\" ? "" :
        $_
    } @{ $match->{part} };
}

sub rule_bool {
    my ($self, %args) = @_;
    my $match = $args{match};
    if ($match->{bool} eq 'true') { true } else { false }
}

sub rule_num {
    my ($self, %args) = @_;
    my $match = $args{match};
    if    ($match->{num} eq 'inf') { "Inf"+0 }
    elsif ($match->{num} eq 'nan') { "NaN"+0 }
    else                           { $match->{num}+0.0 }
}

sub rule_var {
    my ($self, %args) = @_;
    my $match = $args{match};
    $self->vars->{ $match->{var} };
}

sub rule_func {
    my ($self, %args) = @_;
    my $match = $args{match};
    my $f = $match->{func_name};
    my $args = $match->{args};
    my $res;
    if    ($f eq 'length') { $res = length($args->[0]) }
    elsif ($f eq 'ceil'  ) { $res = POSIX::ceil($args->[0]) }
    elsif ($f eq 'floor' ) { $res = POSIX::floor($args->[0]) }
    elsif ($f eq 'rand'  ) { $res = rand() }
    else                   { $res = "undef function $f" }
    $res;
}

sub rule_postprocess {
    my ($self, %args) = @_;
    my $result = $args{result};
    $result;
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
