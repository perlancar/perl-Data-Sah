package Data::Sah::Lang::fr_FR;

use 5.010;
use strict;
use warnings;
use Tie::IxHash;

# VERSION

our %translations;
tie %translations, 'Tie::IxHash', (

    # punctuations

    q[, ],
    q[, ],

    q[: ],
    q[: ],

    q[. ],
    q[. ],

    q[(],
    q[(],

    q[)],
    q[)],

    # modal verbs

    q[must ],
    q[doit ],

    q[must be ],
    q[doit être ],

    q[must not ],
    q[ne doit pas ],

    q[must not be ],
    q[ne doit pas être ],

    q[should ],
    q[devrait ],

    q[should be ],
    q[faut être ],

    q[should not ],
    q[devrait pas ],

    q[should not be ],
    q[devrait pas être ],

    # multi

    q[%s and %s],
    q[%s et %s],

    q[%s or %s],
    q[%s ou %s],

    q[one of %s],
    q[une des %s],

    q[all of %s],
    q[toutes les valeurs %s],

    q[%(modal_verb)ssatisfy all of the following],
    q[%(modal_verb)ssatisfaire toutes les conditions suivantes],

    q[%(modal_verb)ssatisfy one of the following],
    q[%(modal_verb)ssatisfaire une des conditions suivantes],

    q[%(modal_verb)ssatisfy between %d and %d of the following],
    q[%(modal_verb)ssatisfaire entre %d et %d des conditions suivantes],

    # type: BaseType

    # type: Sortable

    # type: Comparable

    # type: HasElems

    # type: num

    # type: int

    q[integer],
    q[nombre entier],

    q[integers],
    q[nombres entiers],

    q[%(modal_verb_be)sdivisible by %s],
    q[%(modal_verb_be)sdivisible par %s],

    q[%(modal_verb)sleave a remainder of %2$s when divided by %1$s],
    q[%(modal_verb)slaisser un reste %2$s si divisé par %1$s],

);

1;
# ABSTRACT: fr_FR locale

=for Pod::Coverage .+
