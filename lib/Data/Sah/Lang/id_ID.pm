package Data::Sah::Lang::id_ID;

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

    q[must],
    q[harus],

    q[must not],
    q[tidak boleh],

    q[should],
    q[sebaiknya],

    q[should not],
    q[sebaiknya tidak],

    # multi

    q[%s and %s],
    q[%s dan %s],

    q[%s or %s],
    q[%s atau %s],

    q[%s nor %s],
    q[%s maupun %s],

    q[one of %s],
    q[salah satu dari %s],

    q[all of %s],
    q[semua dari nilai-nilai %s],

    q[any of %s],
    q[satupun dari %s],

    q[none of %s],
    q[tak satupun dari %s],

    q[%(modal_verb)s satisfy all of the following],
    q[%(modal_verb)s memenuhi semua ketentuan ini],

    q[%(modal_verb)s satisfy none all of the following],
    q[%(modal_verb)s melanggar semua ketentuan ini],

    q[%(modal_verb)s satisfy one of the following],
    q[%(modal_verb)s memenuhi salah satu ketentuan ini],

    # type: BaseType

    q[default value is %s],
    q[jika tidak diisi diset ke %s],

    q[required %s],
    q[%s wajib diisi],

    q[optional %s],
    q[%s opsional],

    q[forbidden %s],
    q[%s tidak boleh diisi],

    # type: Sortable

    q[%(modal_verb)s be at least %s],
    q[%(modal_verb)s minimal %s],

    q[%(modal_verb)s be larger than %s],
    q[%(modal_verb)s lebih besar dari %s],

    q[%(modal_verb)s be at most %s],
    q[%(modal_verb)s maksimal %s],

    q[%(modal_verb)s be smaller than %s],
    q[%(modal_verb)s lebih kecil dari %s],

    q[%(modal_verb)s be between %s and %s],
    q[%(modal_verb)s antara %s dan %s],

    q[%(modal_verb)s be larger than %s and smaller than %s],
    q[%(modal_verb)s lebih besar dari %s dan lebih kecil dari %s],

    # type: Comparable

    q[%(modal_verb)s have the value %s],
    q[%(modal_verb)s bernilai %s],

    q[%(modal_verb)s one of %s],
    q[%(modal_verb)s salah satu dari %s],

    # type: HasElems

    # type: num

    q[number],
    q[bilangan],

    q[numbers],
    q[bilangan],

    # type: int

    q[integer],
    q[bilangan bulat],

    q[integers],
    q[bilangan bulat],

    q[%(modal_verb)s be divisible by %s],
    q[%(modal_verb)s dapat dibagi oleh %s],

    q[%(modal_verb)s leave a remainder of %2$s when divided by %1$s],
    q[jika dibagi %1$s %(modal_verb)s menyisakan %2$s],

    # type: float

    q[%(modal_verb)s be a NaN],
    q[%(modal_verb)s NaN],

    q[%(modal_verb_neg)s be a NaN],
    q[%(modal_verb_neg)s NaN],

    q[%(modal_verb)s be an infinity],
    q[%(modal_verb)s tak hingga],

    q[%(modal_verb_neg)s be an infinity],
    q[%(modal_verb_neg)s tak hingga],

    q[%(modal_verb)s be a positive infinity],
    q[%(modal_verb)s positif tak hingga],

    q[%(modal_verb_neg)s be a positive infinity],
    q[%(modal_verb_neg)s positif tak hingga],

    q[%(modal_verb)s be a negative infinity],
    q[%(modal_verb)s negatif tak hingga],

    q[%(modal_verb)s be a negative infinity],
    q[%(modal_verb)s negatif tak hingga],

    # type: array

    q[array],
    q[deret],

    q[arrays],
    q[deret],

    q[%s of %s],
    q[%s %s],

    q[each element %(modal_verb)s be],
    q[setiap elemennya %(modal_verb)s],
);

1;
# ABSTRACT: id_ID locale

=for Pod::Coverage .+
