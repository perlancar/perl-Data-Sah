package Data::Sah;

# split because loading Regexp::Grammars, as well as compiling the grammar, is
# quite heavy.

use 5.010;

sub parse_string_shortcuts {
    my ($self, $str) = @_;

    use Regexp::Grammars;
    state $grammar = qr{
        ^<Answer>$

        <rule: Answer>
            <MATCH=Either_All> | <MATCH=Array> | <MATCH=Hash>

        # {k=>v, ...}
        <rule: Hash>
            \{ <[Operand=Pair]> ** (,) \}
                (?{
                    $MATCH = [ hash => {} ];
                    for (@{ $MATCH{Operand} }) {
                        my ($k, $v) = @$_;
                        if ($k eq '*') {
                            $MATCH->[1]{values_of} = $v;
                        } else {
                            $MATCH->[1]{keys} //= {};
                            $MATCH->[1]{keys}{$k} = $v;
                        }
                    }
                })

        <rule: Pair>
            <Literal> =\> <Answer>
                (?{
                    $MATCH = [ $MATCH{Literal}, $MATCH{Answer} ];
                })

        # [a, b, ...]
        <rule: Array>
            \[ <[Operand=Star_Sub]> ** (,) \]
                (?{
                    $MATCH = [ array => {elems => $MATCH{Operand}} ];
                })

        # a|b and a&b
        <rule: Either_All>
            <[Operand=Star_Sub]> ** <[Op=([&|])]>
                # XXX: catch mixed: a|b&c
                (?{
                    $MATCH = @{ $MATCH{Operand} } == 1 ?
                        $MATCH{Operand}[0] :
                        [ $MATCH{Op}[0] eq '&' ? 'all' : 'either', => {of => $MATCH{Operand}} ];
                })

        # a* and a[]
        <rule: Star_Sub>
            <Operand=Term> <[Op=(\[\]|\[\d+\]|\[\d+-\]|\[-\d+\]|\[\d+-\d+\]|\*?)]>+
                (?{ $MATCH = $MATCH{Operand};
                    for (@{ $MATCH{Op} }) {
                        if ($_ eq '*') {
                            $MATCH = ref($MATCH) ?
                                [$MATCH->[0], { %{ $MATCH->[1] }, req=>1 }] :
                            [$MATCH, { req=>1 }];
                        } elsif (substr($_, 0, 1) eq '[') {
                            my $l = length($_)-2;
                            $_ = substr($_, 1, $l); # strip the [ and ]
                            my $i = index($_, '-');
                            if ($_ eq '') {
                                $MATCH = [array => {of => $MATCH}];
                            } elsif ($i == -1) {
                                $MATCH = [array => {of => $MATCH, len=>$_}];
                            } elsif ($i == 0) {
                                $MATCH = [array => {of => $MATCH,
                                                    maxlen=>substr($_, 1)}];
                            } elsif ($i == length($_)-1) {
                                $MATCH = [array => {of => $MATCH,
                                                    minlen=>substr($_, 0, $l-1)}];
                            } else {
                                $MATCH = [array => {of => $MATCH,
                                                    minlen=>substr($_, 0, $i),
                                                    maxlen=>substr($_, $i+1),
                                                }];
                            }
                        }
                    }
                })

        # a and (a)
        <rule: Term>
               <MATCH=Typename>
          |    <MATCH=Array>
          |    <MATCH=Hash>
          | \( <MATCH=Answer> \)

        <token: Typename>
            <MATCH=( \w+ )>

        <token: Literal>
            # XXX support quotes and escape inside quotes
            #<MATCH=( \* | \w+ | "[^"]*" | '[^"]*' )>
            <MATCH=( \* | \w+ )>
    }xms;

    return unless $str =~ $grammar;
    $/{Answer};
}

1;
