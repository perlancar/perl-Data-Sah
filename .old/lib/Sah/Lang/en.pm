package Data::Schema::Lang::en;
# ABSTRACT: English translation for Data::Schema messages

use 5.010;
use Any::Moose;

sub translate {
    my ($self, @args) = @_;

    state $translations = {
        should                  => 'should',
        must                    => 'must',
        should_not              => 'should not',
        must_not                => 'must not',

        All                     => '',
        All_of                  => '%(mverb) be all of the following:',
        All_of_i                => '%(mverb) be%(1)',
        All_fail                => 'Does not satisfy this requirement:',

        Array                   => 'array',
        Array_SANITY            => '%(mverb) be an array',
        Array_unique_0          => '%(mverb_not) have unique elements',
        Array_unique_1          => '%(mverb) have unique elements',
        Array_elements          => 'specification for elements:',
        Array_elements_i        => 'element #%(0)%(1)',
        Array_some_of_min       => '%(mverb) contain at least %(1) element(s) which is%(0)',
        Array_some_of_max       => '%(mverb) contain at most %(1) element(s) which is%(0)',
        Array_some_of           => '%(mverb) contain:',
        Array_some_of_between   => 'between %(1) and %(2) of element(s) which is%(0)',
        Array_elements_regex    => '%(mverb) satisfy:',
        Array_elements_regex_if => 'if element index matches regex pattern %(0)',
        Array_elements_regex_then => 'then element %(mverb) be%(0)',

        Base_required           => '%(mverb) be provided',
        Base_forbidden          => '%(mverb_not) be provided',
        Base_default            => 'default value is %(0)D',

        Bool                    => 'true/false',

        Either                  => '',
        Either_of               => '%(mverb) be one of the following:',

        Float                   => 'decimal number',

        HasElement_max_len      => 'length %(mverb) be at most %(0)',
        HasElement_min_len      => 'length %(mverb) be at least %(0)',
        HasElement_len_between  => 'length %(mverb) be between %(0) and %(1)',
        HasElement_len          => 'length %(mverb) be %(0)',
        HasElement_all_elements => 'elements %(mverb) be%(0)',
        HasElement_element_deps => 'these dependencies between elements %(mverb) be satisfied:',
        HasElement_element_deps_if   => 'if elements that match %(0)D are%(1)',
        HasElement_element_deps_then => 'then elements that match %(0)D %(mverb) be%(1)',

        Int                     => 'integer',
        Int_mod                 => 'number modulus %(0) %(mverb) be %(1)',
        Int_divisible_by        => '%(mverb) be divisible by %(0)',
        Int_not_divisible_by    => '%(mverb_not) be divisible by %(0)',

        #Num
        Num_SANITY              => '%(mverb) be a number',

        Str                     => 'text',
        Str_match               => '%(mverb) match regex pattern %(0)',
        Str_not_match           => '%(mverb_not) match regex pattern %(0)',
        Str_isa_regex_0         => '%(mverb_not) be a regex pattern',
        Str_isa_regex_1         => '%(mverb) be a regex pattern',

        Typename_SANITY         => '%(mverb) be a valid type name',
    };

    if (wantarray) {
        map { $translations->{$_} } @args;
    } else {
        $translations->{$args[0]};
    }
};

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
