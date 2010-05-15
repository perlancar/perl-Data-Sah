package Data::Schema::ParseShortcut;

# this package is used to save some compilation time.

use feature 'state';
use strict;
use warnings;

sub __parse_shortcuts {
    my ($str) = @_;

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
            <Operand=Term> <[Op=(\[\]|\*?)]>+
                (?{ $MATCH = $MATCH{Operand};
                    for (@{ $MATCH{Op} }) {
                        if ($_ eq '[]') {
                            $MATCH = [array => {of => $MATCH}];
                        } elsif ($_ eq '*') {
                            $MATCH = ref($MATCH) ?
                                [$MATCH->[0], { %{ $MATCH->[1] }, set=>1 }] :
                            [$MATCH, { set=>1 }];
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
