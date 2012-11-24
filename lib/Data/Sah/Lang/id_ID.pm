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

    q[must ],
    q[harus ],

    q[must be ],
    q[harus ],

    q[must not ],
    q[tidak boleh ],

    q[must not be ],
    q[tidak boleh ],

    q[should ],
    q[sebaiknya ],

    q[should be ],
    q[sebaiknya ],

    q[should not ],
    q[sebaiknya tidak ],

    q[should not be ],
    q[sebaiknya tidak ],

    # multi

    q[%s and %s],
    q[%s dan %s],

    q[%s or %s],
    q[%s atau %s],

    q[one of %s],
    q[salah satu dari %s],

    q[all of %s],
    q[semua nilai-nilai %s],

    q[%(modal_verb_opt)ssatisfy all of the following],
    q[%(modal_verb_opt)smemenuhi semua ketentuan ini],

    q[%(modal_verb_opt)sfail all of the following],
    q[%(modal_verb_opt)smelanggar semua ketentuan ini],

    q[%(modal_verb_opt)ssatisfy one of the following],
    q[%(modal_verb_opt)smemenuhi salah satu ketentuan ini],

    q[%(modal_verb_opt)ssatisfy between %(min_ok)d and %(max_ok)d of the following],
    q[%(modal_verb_opt)smemenuhi antara %(min_ok)d hingga %(max_ok)d ketentuan ini],

    q[%(modal_verb_opt)sfail between %(min_nok)d and %(max_nok)d of the following],
    q[%(modal_verb_opt)smelanggar antara %(min_nok)d hingga %(max_nok)d ketentuan ini],

    q[%(modal_verb_opt)ssatisfy between %(min_ok)d and %(max_ok)d and fail between %(min_nok)d and %(max_nok)d of the following],
    q[%(modal_verb_opt)smemenuhi antara %(min_ok)d hingga %(max_ok)d dan melanggar %(min_nok)d hingga %(max_nok)d ketentuan ini],

    # type: BaseType

    q[default value %s],
    q[jika tidak diisi diset ke %s],

    q[required %s],
    q[%s wajib diisi],

    q[optional %s],
    q[%s opsional],

    q[forbidden %s],
    q[%s yang tidak boleh diisi],

    # type: Sortable

    q[%(modal_verb_be_opt)sat least %s],
    q[%(modal_verb_be_opt)sminimal %s],

    q[%(modal_verb_be_opt)slarger than %s],
    q[%(modal_verb_be_opt)slebih besar dari %s],

    q[%(modal_verb_be_opt)sat most %s],
    q[%(modal_verb_be_opt)smaksimal %s],

    q[%(modal_verb_be_opt)ssmaller than %s],
    q[%(modal_verb_be_opt)slebih kecil dari %s],

    q[%(modal_verb_be_opt)sbetween %s and %s],
    q[%(modal_verb_be_opt)santara %s dan %s],

    q[%(modal_verb_be_opt)slarger than %s and smaller than %s],
    q[%(modal_verb_be_opt)slebih besar dari %s dan lebih kecil dari %s],

    # type: Comparable

    q[%(modal_verb_be_opt)shave the value %s],
    q[%(modal_verb_be_opt)sbernilai %s],

    q[%(modal_verb_be_opt)sone of %s],
    q[%(modal_verb_be_opt)ssalah satu dari %s],

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

    q[%(modal_verb_be_opt)sdivisible by %s],
    q[%(modal_verb_be_opt)sdapat dibagi %s],

    q[%(modal_verb_opt)sleave a remainder of %2$s when divided by %1$s],
    q[jika dibagi %1$s %(modal_verb)smenyisakan %2$s],

    # type: float

    q[%(modal_verb_be_opt)sa NaN],
    q[%(modal_verb_be_opt)sNaN],

    q[%(modal_verb_not_be)sa NaN],
    q[%(modal_verb_not_be)sNaN],

    q[%(modal_verb_be_opt)san infinity],
    q[%(modal_verb_be_opt)stak hingga],

    q[%(modal_verb_not_be)san infinity],
    q[%(modal_verb_not_be)stak hingga],

    q[%(modal_verb_be_opt)sa positive infinity],
    q[%(modal_verb_be_opt)spositif tak hingga],

    q[%(modal_verb_not_be)sa positive infinity],
    q[%(modal_verb_not_be)spositif tak hingga],

    q[%(modal_verb_be_opt)s a negative infinity],
    q[%(modal_verb_be_opt)snegatif tak hingga],

    q[%(modal_verb_not_be)sa negative infinity],
    q[%(modal_verb_not_be)snegatif tak hingga],

    # type: array

    q[array],
    q[deret],

    q[arrays],
    q[deret],

    q[%s of %s],
    q[%s %s],

    q[each element %(modal_verb_be)s],
    q[setiap elemennya %(modal_verb_be)s],
);

1;
# ABSTRACT: id_ID locale

=for Pod::Coverage .+
