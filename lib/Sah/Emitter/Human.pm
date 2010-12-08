package Sah::Emitter::Human;
# ABSTRACT: Emit human text from Sah schema

=head1 SYNOPSIS

    use Sah;
    my $ds = new Sah;
    my $human = $ds->human($schema);

=cut

use Any::Moose;
use warnings::register;
use Log::Any qw($log);
extends 'Sah::Emitter::Base';

sub after_attr {
    my ($self, %args) = @_;
    my $type = ref($args{th}); $type =~ s/.+:://;
    my $res = $self->result;
    my $attr = $args{attr};
    if (!$args{attr_res}) {
        my $a = $attr->{name} eq 'SANITY' ? '' : "_$attr->{name}";
        push @$res, $self->translatef("${type}$a", [$attr->{arg}]);
    }
}

# ---

=head2 stringf($str, $args[, $args2[, ...]])

Substitute C<%(NAME)F> and C<%(0)F>, C<%(1)F>, C<%(-2)F>, and so on in
string with elements from hashrefs/arrayrefs.

$args can be hashref/arrayref. For C<%(0)X>, C<%(1)X> and so on,
arrayrefs will be searched. for C<%(NAME)X>, hashrefs will be
searched.

C<F> is a format code and can be:

Available codes:

=over 4

=item * s

Format as string / dump (if value is a reference). This code is the
default and will be assumed if format code is not specified.

=item * D

Format as dump.

=item * c

Comma-separated list of strings / dumps.

=back

=cut

sub stringf {
    my ($self, $str, @args) = @_;
    my $main = $self->main;
    my $emitp = $main->emitters->{ $self->config->prog_emitter_name };

    $str =~ s!%\(([^)]+)\)(\w?)!
        do {
            my ($orig, $var, $code) = ($&, $1, $2);
            my $result;
            my $val;
            my $found;
            for my $a (@args) {
                if (ref($a) eq 'HASH') {
                    next unless exists $a->{$var};
                    $val = $a->{$var}; $found++; last;
                } elsif (ref($a) eq 'ARRAY') {
                    next unless $var =~ /^-?\d+$/;
                    next if $var >= 0 &&  $var >= @$a;
                    next if $var <  0 && -$var >  @$a;
                    $val = $a->[$var]; $found++; last;
                } else {
                    next;
                }
            }
            unless ($found) {
                $val = "";
                warn "stringf(): Can't find value for `$orig` in `$str`"
                    if warnings::enabled();
            }

            if ($code eq '' || $code eq 's') {
                $result = ref($val) ? $emitp->dump($val) : $val;
            } elsif ($code eq 'D') {
                $result = $emitp->dump($val);
            } elsif ($code eq 'c') {
                $val = [$val] unless ref($val) eq 'ARRAY';
                $result = join(', ',
                               map {ref($_) ? $emitp->dump($_) : $_ } @$val);
            } else {
                $result = $orig;
                warn "stringf(): Unknown code format `$orig`"
                    if warnings::enabled();
            }
            $result;
        };
    !ge;
    $str;
}

=head2 translate($str)

Will search translation for $str in one or more language modules
(Sah::Lang::*::$lang) by invoking translate() in each of
those modules. The list of modules to search can be modified with
B<$ds->register_lang()>.

$lang defaults to config's B<lang> setting.

When translation is not found, the original $str is returned but a
warning is emitted (the warning can be suppressed by using "no
warnings" from your calling code).

=cut

my %Lang_Objects;
sub translate {
    my ($self, $str) = @_;
    my $lang = $self->config->lang;
    my $fallback_lang = 'en';
    my @langs = ($lang);
    push @langs, $fallback_lang unless $lang eq $fallback_lang;

    my $found_lang;
    my $result;
  SEARCH:
    for my $l (@langs) {
        for my $p (@{ $self->main->lang_modules }) {
            my $pkg = "Sah::Lang" . ($p ? "::$p" : "") . "::$l";
            my $translator;
            if (defined $Lang_Objects{$pkg}) {
                $translator = $Lang_Objects{$pkg};
                next unless $translator;
            } else {
                $log->tracef("Trying require(): %s", $pkg);
                eval "require $pkg";
                if ($@) {
                    $Lang_Objects{$pkg} = 0;
                    next;
                } else {
                    $Lang_Objects{$pkg} = $translator = $pkg->new;
                }
            }

            if (defined(my $r = $translator->translate($str))) {
                $result = $r;
                $found_lang = $l;
                last SEARCH;
            }
        }
    }
    if ($found_lang) {
        if ($found_lang ne $lang) {
            warn "translate(): Falling back from language $lang to ".
                "$fallback_lang for `$str`" if warnings::enabled();
        }
        return $result;
    } else {
        warn "translate(): Can't find any translation (langs=".join(", ", @langs).") ".
            "for `$str`" if warnings::enabled();
        return $str;
    }
}

=head2 translatef($str, $args[, $arg2[, ...]])

A shortcut for translate() + stringf().

=cut

sub translatef {
    my ($self, $str, @args) = @_;
    $self->stringf($self->translate($str),
                   @args,
                   {mverb => $self->translate("must"), mverb_not => $self->translate("must_not")});
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
