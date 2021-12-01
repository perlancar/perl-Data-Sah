package Data::Sah::Lang::fr_FR;

use 5.010;
use strict;
use warnings;

use Tie::IxHash;

# currently incomplete

# AUTHORITY
# DATE
# DIST
# VERSION

our %translations;
tie %translations, 'Tie::IxHash', (

    # punctuations

    q[ ], # inter-word boundary
    q[ ],

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

    q[must],
    q[doit],

    q[must not],
    q[ne doit pas],

    q[should],
    q[devrait],

    q[should not],
    q[ne devrait pas],

    # field/fields/argument/arguments

    q[field],
    q[champ],

    q[fields],
    q[champs],

    q[argument],
    q[argument],

    q[arguments],
    q[arguments],

    # multi

    q[%s and %s],
    q[%s et %s],

    q[%s or %s],
    q[%s ou %s],

    q[one of %s],
    q[une des %s],

    q[all of %s],
    q[toutes les valeurs %s],

    q[%(modal_verb)s satisfy all of the following],
    q[%(modal_verb)s satisfaire à toutes les conditions suivantes],

    q[%(modal_verb)s satisfy one of the following],
    q[%(modal_verb)s satisfaire l'une des conditions suivantes],

    q[%(modal_verb)s satisfy none of the following],
    q[%(modal_verb)s satisfaire à aucune des conditions suivantes],

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

    q[%(modal_verb)s be divisible by %s],
    q[%(modal_verb)s être divisible par %s],

    q[%(modal_verb)s leave a remainder of %2$s when divided by %1$s],
    q[%(modal_verb)s laisser un reste %2$s si divisé par %1$s],

    # messages for compiler
);

1;
# ABSTRACT: fr_FR locale

=for Pod::Coverage .+
