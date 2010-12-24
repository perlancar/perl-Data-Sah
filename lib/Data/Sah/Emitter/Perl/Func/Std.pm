package Data::Sah::Emitter::Perl::Func::Std;

use Any::Moose;

extends 'Sah::Emitter::ProgBase::Func::Base';
with 'Sah::Spec::v10::Func::Std';

sub func_abs {}
sub func_add {}
sub func_atan2 {}
sub func_ceil {}
sub func_chomp {}
sub func_cirsort {}
sub func_cisort {}
sub func_cos {}
sub func_count {}
sub func_defined {}
sub func_divide {}
sub func_element {}
sub func_exists {}
sub func_exp {}
sub func_flip {}
sub func_float {}
sub func_floor {}
sub func_hex {}
sub func_if {}
sub func_index {}
sub func_invert {}
sub func_join {}
sub func_keys {}
sub func_lc {}
sub func_lcfirst {}
sub func_length {}
sub func_log {}
sub func_ltrim {}
sub func_multiply {}
sub func_negative {}
sub func_nrsort {}
sub func_nsort {}
sub func_oct {}
sub func_pow {}
sub func_rand {}
sub func_re_match {}
sub func_re_replace {}
sub func_re_replace_once {}
sub func_reverse {}
sub func_rindex {}
sub func_rsort {}
sub func_rtrim {}
sub func_sin {}
sub func_sort {}
sub func_split {}

sub func_sqrt {
    my ($self) = @_;
    my $e = $self->emitter;

    $e->line('$_[0]**0.5;');
}

sub func_substr {}
sub func_trim {}
sub func_typeof {}
sub func_uc {}
sub func_ucfirst {}
sub func_values {}

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
