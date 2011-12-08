package Data::Sah::Compiler::Human;

=head1 SYNOPSIS

    use Sah;
    my $ds = new Sah;
    my $human = $ds->human($schema);

=cut

use Moo;
use warnings::register;
use Log::Any qw($log);
extends 'Data::Sah::Compiler::Base';

sub after_clause {
    my ($self, %args) = @_;
    my $type = ref($args{th}); $type =~ s/.+:://;
    my $res = $self->result;
    my $clause = $args{clause};
    if (!$args{clause_res}) {
        my $c = $clause->{name} eq 'SANITY' ? '' : "_$clause->{name}";
        push @$res, $self->translatef("${type}$c", [$clause->{arg}]);
    }
}


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
            my $pkg = "Data::SahLang" . ($p ? "::$p" : "") . "::$l";
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

1;
# ABSTRACT: Emit human text from Sah schema
