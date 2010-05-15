package Data::Schema::Schema::Schema;
# ABSTRACT: the DS schema of DS schema

=head1 SYNOPSIS

 # validate your schemas!

 use Data::Schema -schemas => ['Schema'];
 my $ds = new Data::Schema;
 my $validator = $ds->compile('schema');

 my $schema = [hash => {foo => 1}];
 my $res = $validator->($schema);
 $res->{success} or die "Schema is not valid!";

=head1 DESCRIPTION

This module contains the schema for Data::Schema schema ("schema")
itself. You can use it to validate your schemas.

This schema currently can only be compiled to Perl as it uses
C<Regexp::Grammars> which is not available in PHP or JavaScript.

I apologize for the confusing package name :-)

=cut

# XXX first attrhash must not contain merge prefix, unless merge
# prefix is keep or type is schema type. currently we allow merge
# prefixes.

# XXX when defining subschema, type name must not be known (do not
# clash with existing types)

# XXX allow options key for merging: MERGE_OPTS in all hashes which
# restrict possible keys

use strict;
use warnings;
use feature 'state';

my $sch_regex = [str => {set=>1, isa_regex=>1}];
my $sch_array_of_any = [array => {set=>1, of=>[any=>{set=>1}]}];
my $sch_array_of_str = [array => {set=>1, of=>[str=>{set=>1}]}];
my $sch_array_of_int = [array => {set=>1, of=>[int=>{set=>1}]}];
my $sch_array_of_regex = [array => {set=>1, of=>$sch_regex}];

my $sch_1form = [typename => {set => 1, known => 1 }];

my $sch_2form = [array => {
			   set=>1,
			   minlen=>1,
			   elem_regex => {
					  '\A0\z'     => $sch_1form,
					  '\A[1-9]\z' => [hash => {set=>1}],
					 },
			   elem_deps => [], # LATER:ELEM_DEPS
			  }
		];

my $sch_3form = [hash => {
			  set=>1,
			  required_keys => ['type'],
			  keys => {
				   type => $sch_1form,
				   attr_hashes => [array => {set=>1, of=>[hash => {set=>1}]}],
				   def => '', # RECURSIVE:SCHEMA
				  },
			  key_deps => [], # LATER:KEY_DEPS
			 }
		];

my $sch_schema = [either => {set=>1, 
			     of=>[qw/str array hash/],
			     deps=>[
				    [str => $sch_1form],
				    [array => $sch_2form],
				    [hash => $sch_3form],
				   ]
			    }
		 ];

$sch_3form->[1]{keys}{def} = [hash => {
    keys_of => "typename",
    #keys_prefilter => [re_replace => '^\?(.+)', '\1'],
    values_of => $sch_schema,
}]; # RECURSIVE:SCHEMA

my $sch_array_of_schema = [array => {set=>1, of=>$sch_schema}];

sub _add_deps($$) {
    my ($names, $sch_attrs) = @_;

    my $re_prefix          = '(?:[*+.!^-])';
    my $re_suffix_all      = '(?::(?:comment|note|warnmsg|errmsg|err|warn))';
    my $re_suffix_cmt      = '(?::(?:comment|note))';
    my $re_suffix_msg      = '(?::(?:warnmsg|errmsg))';
    my $re_suffix_lvl      = '(?::(?:err|warn))';
    my $re_name            = '(?:[a-z_][a-z0-9_]{0,63})';

    my $sch_attrhash = [
	hash => {
	    set => 1,
	    allow_extra_keys => 0,
	    keys_regex => {
		"\\A$re_prefix?" . '_'                                    => "str", # ignore attribute whose name starts with underscore
		"\\A$re_prefix?" . "$re_name?" . $re_suffix_cmt    . '\z' => "str",
		"\\A$re_prefix?" . "$re_name?" . $re_suffix_msg    . '\z' => "str",
		"\\A$re_prefix?" .               $re_suffix_lvl    . '\z' => [bool => {set=>1}],
		map { 
                "\\A$re_prefix?" . $_          . "$re_suffix_lvl?" . '\z' => $sch_attrs->{$_} 
		} keys %$sch_attrs
	    },
	    #keys_dep => {}, # XXX: required/forbidden/set must not conflict
	}
	];

    my $elem_dep = [
	'\A0\z'   => [str => {one_of=>$names}],
	'[1-9]' => $sch_attrhash,
	];
    push @{ $sch_2form->[1]{elem_deps} }, $elem_dep; # ELEM_DEPS

    my $key_dep = [
	'\Atype\z'    => [str => {one_of=>$names}],
	'attr_hashes' => [array => {set=>1, elem_regex => {'.*'=>$sch_attrhash} }],
	];
    push @{ $sch_3form->[1]{key_deps} }, $key_dep; # KEY_DEPS
}

my %attrs_base;
$attrs_base{comment}      = "any";
$attrs_base{note}         = $attrs_base{comment};
$attrs_base{required}     = "bool",
$attrs_base{forbidden}    = $attrs_base{required};
$attrs_base{set}          = $attrs_base{required};
$attrs_base{default}      = "any";

my %attrs_comparable;
$attrs_comparable{one_of}       = $sch_array_of_any;
$attrs_comparable{is_one_of}    = $attrs_comparable{one_of};
$attrs_comparable{not_one_of}   = $attrs_comparable{one_of};
$attrs_comparable{isnt_one_of}  = $attrs_comparable{not_one_of};
$attrs_comparable{is}           = [any => {set=>1}];
$attrs_comparable{isnt}         = $attrs_comparable{is};
$attrs_comparable{not}          = $attrs_comparable{isnt};

my %attrs_sortable;
$attrs_sortable{min}          = [any => {set=>1}];
$attrs_sortable{ge}           = $attrs_sortable{min};
$attrs_sortable{max}          = $attrs_sortable{min};
$attrs_sortable{le}           = $attrs_sortable{max};
$attrs_sortable{minex}        = $attrs_sortable{min};
$attrs_sortable{gt}           = $attrs_sortable{minex};
$attrs_sortable{maxex}        = $attrs_sortable{min};
$attrs_sortable{lt}           = $attrs_sortable{maxex};
$attrs_sortable{between}      = [array => {set=>1, len=>2, elem=>[$attrs_sortable{min}, $attrs_sortable{max}]}];

my %attrs_scalar;
$attrs_scalar{deps}           = [array => {set=>1, of=>[array=>{set=>1, len=>2, elems=>[$sch_schema, $sch_schema] }]}];
$attrs_scalar{dep}            = $attrs_scalar{deps};

my %attrs_num = (%attrs_base, %attrs_comparable, %attrs_sortable, %attrs_scalar);
_add_deps(['float'], \%attrs_num);

my %attrs_int = (%attrs_num);
$attrs_int{mod}               = [array => {set=>1, len=>2, elems=>[ [int=>{set=>1, not=>0}], [int=>{set=>1}] ] }];
$attrs_int{divisible_by}      = [either=>{of=>[ [int=>{set=>1, not=>0}] ,
                                                [array=>{set=>1, of=>[int=>{set=>1, not=>0}]}] ]}];
$attrs_int{not_divisible_by}  = $attrs_int{divisible_by};
$attrs_int{indivisible_by}    = $attrs_int{not_divisible_by};
_add_deps(['int', 'integer'], \%attrs_int);

my %attrs_haselement;
$attrs_haselement{max_len}        = [int => {set=>1}];
$attrs_haselement{maxlen}         = $attrs_haselement{max_len};
$attrs_haselement{max_length}     = $attrs_haselement{max_len};
$attrs_haselement{maxlength}      = $attrs_haselement{max_len};
$attrs_haselement{min_len}        = $attrs_haselement{max_len};
$attrs_haselement{minlen}         = $attrs_haselement{max_len};
$attrs_haselement{min_length}     = $attrs_haselement{max_len};
$attrs_haselement{minlength}      = $attrs_haselement{max_len};
$attrs_haselement{len}            = $attrs_haselement{max_len};
$attrs_haselement{length}         = $attrs_haselement{max_len};
$attrs_haselement{len_between}    = [array => {set=>1, len=>2, of=>[int=>{set=>1}]}];
$attrs_haselement{length_between} = $attrs_haselement{len_between};
$attrs_haselement{all_elements}   = $sch_schema;
$attrs_haselement{all_element}    = $attrs_haselement{all_elements};
$attrs_haselement{all_elems}      = $attrs_haselement{all_elements};
$attrs_haselement{all_elem}       = $attrs_haselement{all_elements};
$attrs_haselement{element_deps}   = [array => {set=>1, of=>[array=>{set=>1, len=>4, elems=>[ $sch_regex, $sch_schema, $sch_regex, $sch_schema ] }]}];
$attrs_haselement{element_dep}    = $attrs_haselement{element_deps};
$attrs_haselement{elem_deps}      = $attrs_haselement{element_deps};
$attrs_haselement{elem_dep}       = $attrs_haselement{element_deps};

my %attrs_str = (%attrs_base, %attrs_comparable, %attrs_sortable, %attrs_scalar, %attrs_haselement);
$attrs_str{match}               = $sch_regex;
$attrs_str{matches}             = $attrs_str{match};
$attrs_str{not_match}           = $attrs_str{match};
$attrs_str{not_matches}         = $attrs_str{match};
$attrs_str{isa_regex}           = "bool";
_add_deps(['str', 'string', 'cistr', 'cistring'], \%attrs_str);

my %attrs_bool = (%attrs_base, %attrs_comparable, %attrs_sortable, %attrs_scalar);
_add_deps(['bool', 'boolean'], \%attrs_bool);

my %attrs_and = (%attrs_base, %attrs_scalar);
$attrs_and{of} = $sch_array_of_schema;
_add_deps(['all', 'and', 'either', 'or', 'any'], \%attrs_and);

my %attrs_typename = (%attrs_str);
$attrs_typename{known}      = "bool";
$attrs_typename{isa_schema} = "bool";
_add_deps(['typename'], \%attrs_typename);

my %attrs_obj = (%attrs_base, %attrs_scalar);
$attrs_obj{can_one}    = [either => {of=>[ [str=>{set=>1}], [array=>{set=>1, of=>[str=>{set=>1}]}] ]}];
$attrs_obj{can_all}    = $attrs_obj{can_one};
$attrs_obj{can}        = $attrs_obj{can_one};
$attrs_obj{cannot}     = $attrs_obj{can_one};
$attrs_obj{cant}       = $attrs_obj{can_one};
$attrs_obj{isa_one}    = $attrs_obj{can_one};
$attrs_obj{isa_all}    = $attrs_obj{can_one};
$attrs_obj{isa}        = $attrs_obj{can_one};
$attrs_obj{not_isa}    = $attrs_obj{can_one};
_add_deps(['obj', 'object'], \%attrs_obj);

my %attrs_array = (%attrs_base, %attrs_comparable, %attrs_sortable, %attrs_scalar, %attrs_haselement);
$attrs_array{unique}         = "bool";
$attrs_array{elements}       = $sch_array_of_schema;
$attrs_array{element}        = $attrs_array{elements};
$attrs_array{elems}          = $attrs_array{elements};
$attrs_array{elem}           = $attrs_array{elements};
$attrs_array{of}             = $attrs_haselement{all_elements};
$attrs_array{some_of}        = [array => {set=>1, of=>[array => {set=>1, len=>3, elems=>[ $sch_schema, [int=>{set=>1}], [int=>{set=>1}] ] }]}];
$attrs_array{elements_regex} = [hash => {set=>1, keys_of=>$sch_regex, values_of=>$sch_schema}];
_add_deps(['array'], \%attrs_array);

my %attrs_hash = (%attrs_base, %attrs_comparable, %attrs_sortable, %attrs_scalar, %attrs_haselement);
$attrs_hash{keys_match}               = $sch_regex;
$attrs_hash{allowed_keys_regex}       = $attrs_hash{keys_match};
$attrs_hash{keys_not_match}           = $attrs_hash{keys_match};
$attrs_hash{forbidden_keys_regex}     = $attrs_hash{keys_match};
$attrs_hash{keys_one_of}              = $sch_array_of_str;
$attrs_hash{allowed_keys}             = $attrs_hash{keys_one_of};
$attrs_hash{values_one_of}            = $sch_array_of_any;
$attrs_hash{allowed_values}           = $attrs_hash{values_one_of};
$attrs_hash{required_keys}            = $sch_array_of_str;
$attrs_hash{required_keys_regex}      = $sch_regex;
$attrs_hash{keys}                     = [hash => {set=>1, keys_of=>[str => {set=>1}], values_of=>$sch_schema}];
$attrs_hash{keys_of}                  = $sch_schema;
$attrs_hash{all_keys}                 = $attrs_hash{keys_of};
$attrs_hash{of}                       = $attrs_haselement{all_elements};
$attrs_hash{all_values}               = $attrs_haselement{all_elements};
$attrs_hash{values_of}                = $attrs_haselement{all_elements};
$attrs_hash{some_of}                  = [array => {set=>1, of=>[array => {set=>1, len=>4, elems=>[ $sch_schema, $sch_schema, [int=>{set=>1}], [int=>{set=>1}] ] }]}];
$attrs_hash{keys_regex}               = [hash => {set=>1, keys_of=>$sch_regex, values_of=>$sch_schema}];
$attrs_hash{values_match}             = $sch_regex;
$attrs_hash{allowed_values_regex}     = $attrs_hash{values_match};
$attrs_hash{values_not_match}         = $attrs_hash{values_match};
$attrs_hash{forbidden_values_regex}   = $attrs_hash{values_match};
$attrs_hash{key_deps}                 = $attrs_haselement{element_deps};
$attrs_hash{key_dep}                  = $attrs_haselement{element_deps};
$attrs_hash{allow_extra_keys}         = [bool => {set=>1}];
$attrs_hash{conflicting_keys}         = [array => {set=>1, of=>$sch_array_of_str}];
$attrs_hash{conflicting_keys_regex}   = [array => {set=>1, of=>$sch_array_of_regex}];
$attrs_hash{codependent_keys}         = $attrs_hash{conflicting_keys};
$attrs_hash{codependent_keys_regex}   = $attrs_hash{conflicting_keys_regex};
_add_deps(['hash'], \%attrs_hash);

sub schemas {
    state $a = {
        'schema' => $sch_schema,
    };
}

=head1 TODO

* First form shortcuts.

* Parse

* Prefilters/postfilters must be valid expressions, functions must be
known.

* Attribute conlicts.

=cut

1;
