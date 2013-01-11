package Data::Sah::Lang::id_ID;

use 5.010;
use strict;
use warnings;
use Tie::IxHash;

# VERSION

sub ordinate {
    my ($n, $noun) = @_;
    "$noun ke-$n";
}

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

    # type: Comparable

    q[%(modal_verb)s have the value %s],
    q[%(modal_verb)s bernilai %s],

    q[%(modal_verb)s one of %s],
    q[%(modal_verb)s salah satu dari %s],

    # type: HasElems

    q[length %(modal_verb)s be %s],
    q[panjang %(modal_verb)s %s],

    q[length %(modal_verb)s be at least %s],
    q[panjang %(modal_verb)s minimal %s],

    q[length %(modal_verb)s be at most %s],
    q[panjang %(modal_verb)s maksimal %s],

    q[length %(modal_verb)s be between %s and %s],
    q[panjang %(modal_verb)s antara %s dan %s],

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

    # type: all

    q[%(modal_verb)s be %s],
    q[%(modal_verb)s %s],

    q[as well as %s],
    q[juga %s],

    q[%(modal_verb)s be all of the following],
    q[%(modal_verb)s merupakan semua ini],

    # type: any

    q[%(modal_verb)s be either %s],
    q[%s],

    q[or %s],
    q[atau %s],

    q[%(modal_verb)s be one of the following],
    q[%(modal_verb)s merupakan salah satu dari],

    # type: array

    q[array],
    q[larik],

    q[arrays],
    q[larik],

    q[%s of %s],
    q[%s %s],

    q[each array element %(modal_verb)s be],
    q[setiap elemen larik %(modal_verb)s],

    q[%s %(modal_verb)s be],
    q[%s %(modal_verb)s],

    q[element],
    q[elemen],

    q[each array subscript %(modal_verb)s be],
    q[setiap subskrip larik %(modal_verb)s],

    # type: bool

    q[boolean value],
    q[nilai boolean],

    q[boolean values],
    q[nilai boolean],

    q[%(modal_verb)s be true],
    q[%(modal_verb)s bernilai benar],

    q[%(modal_verb)s be false],
    q[%(modal_verb)s bernilai salah],

    # type: code

    q[code],
    q[kode],

    q[codes],
    q[kode],

    # type: float

    q[decimal number],
    q[bilangan desimal],

    q[decimal numbers],
    q[bilangan desimal],

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

    # type: hash

    q[hash],
    q[larik asosiatif],

    q[hashes],
    q[larik asosiatif],

    q[field %s %(modal_verb)s be],
    q[field %s %(modal_verb)s],

    # type: int

    q[integer],
    q[bilangan bulat],

    q[integers],
    q[bilangan bulat],

    q[%(modal_verb)s be divisible by %s],
    q[%(modal_verb)s dapat dibagi oleh %s],

    q[%(modal_verb)s be odd],
    q[%(modal_verb)s ganjil],

    q[%(modal_verb)s be even],
    q[%(modal_verb)s genap],

    q[%(modal_verb)s leave a remainder of %2$s when divided by %1$s],
    q[jika dibagi %1$s %(modal_verb)s menyisakan %2$s],

    # type: num

    q[number],
    q[bilangan],

    q[numbers],
    q[bilangan],

    # type: obj

    q[object],
    q[objek],

    q[objects],
    q[objek],

    # type: re

    q[regex pattern],
    q[pola regex],

    q[regex patterns],
    q[pola regex],

    # type: str

    q[text],
    q[teks],

    q[texts],
    q[teks],

    q[%(modal_verb)s match regex pattern %s],
    q[%(modal_verb)s cocok dengan pola regex %s],

    q[%(modal_verb)s be a regex pattern],
    q[%(modal_verb)s pola regex],

    q[each subscript of the text %(modal_verb)s be],
    q[setiap subskrip dari teks %(modal_verb)s],

    q[each character of the text %(modal_verb)s be],
    q[setiap karakter dari teks %(modal_verb)s],

    q[character],
    q[karakter],

    # messages for compiler

    q[Input does not satisfy the following schema: %s],
    q[Masukan tidak memenuhi skema ini: %s],

    q[Input is not of type %s],
    q[Masukan tidak bertipe %s],

    q[Required input not specified],
    q[Masukan wajib tapi belum diisi],

    q[Forbidden input specified],
    q[Masukan dilarang tapi diisi],

    q[Structure contains unknown field(s) [%%s]],
    q[Struktur mengandung field yang tidak dikenal [%%s]],

);

1;
# ABSTRACT: id_ID locale

=for Pod::Coverage .+
