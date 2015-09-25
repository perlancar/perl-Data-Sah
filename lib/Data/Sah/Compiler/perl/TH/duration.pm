package Data::Sah::Compiler::perl::TH::duration;

# DATE
# VERSION

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Mo qw(build default);
use Role::Tiny::With;
use Scalar::Util qw(blessed looks_like_number);

extends 'Data::Sah::Compiler::perl::TH';
with 'Data::Sah::Type::duration';

sub expr_coerce_term {
    my ($self, $cd, $t) = @_;

    my $c = $self->compiler;

    # to reduce unnecessary overhead, we don't explicitly load
    # DateTime::Duration here, but on demand when doing validation
    #$c->add_module($cd, 'DateTime::Duration');

    # although this module is very lightweight, we also load it on-demand.
    #$c->add_module($cd, 'Time::Duration::Parse::AsHash');

    $c->add_module($cd, 'Scalar::Util');

    join(
        '',
        "(",
        "(Scalar::Util::blessed($t) && $t->isa('DateTime::Duration')) ? $t : ",
        "(Scalar::Util::looks_like_number($t) && $t >= 0 ? $t : (require DateTime::Duration && DateTime::Duration->new(seconds=>$t))",
        "$t =~ /\\AP(?:([0-9]+(?:\\.[0-9]+)?)Y)? (?:([0-9]+(?:\\.[0-9]+)?)M)? (?:([0-9]+(?:\\.[0-9]+)?)W)? (?:([0-9]+(?:\\.[0-9]+)?)D)? (?: T (?:([0-9]+(?:\\.[0-9]+)?)H)? (?:([0-9]+(?:\\.[0-9]+)?)M)? (?:([0-9]+(?:\\.[0-9]+)?)S)? )?\\z/x ? require DateTime::Duration && DateTime::Duration->new(years=>\$1||0, months=>\$2||0, weeks=>\$3||0, days=>\$4||0, hours=>\$5||0, minutes=>\$6||0, seconds=>\$7||0) : ",
        "do { my \$d; eval { require Time::Duration::Parse::AsHash; \$d = Time::Duration::Parse::AsHash::parse_duration($t) }; \$@ ? undef : require DateTime::Duration && DateTime::Duration->new(years=>\$d->{years}//0, months=>\$d->{months}//0, weeks=>\$d->{weeks}//0, days=>\$d->{days}//0, hours=>\$d->{hours}//0, minutes=>\$d->{minutes}//0, seconds=>\$d->{seconds}//0) } : die(\"BUG: can't coerce duration\")",
        ")",
    );
}

sub expr_coerce_value {
    my ($self, $cd, $v) = @_;

    my $c = $self->compiler;

    my $d;

    if (blessed($v) && $v->isa('DateTime::Duration')) {
        return join(
            '',
            "DateTime::Duration->new(",
            "years=>",   $v->years,   ",",
            "months=>",  $v->months,  ",",
            "weeks=>",   $v->weeks,   ",",
            "days=>",    $v->days,    ",",
            "hours=>",   $v->hours,   ",",
            "minutes=>", $v->minutes, ",",
            "seconds=>", $v->seconds, ",",
            ")",
        );
    } if (looks_like_number($v) && $v >= 0) {
        return "require DateTime::Duration && DateTime::Duration->new(seconds=>$v)";
    } elsif ($v =~ /\AP
                    (?:([0-9]+(?:\.[0-9]+)?)Y)?
                    (?:([0-9]+(?:\.[0-9]+)?)M)?
                    (?:([0-9]+(?:\.[0-9]+)?)W)?
                    (?:([0-9]+(?:\.[0-9]+)?)D)?
                    (?: T
                        (?:([0-9]+(?:\.[0-9]+)?)H)?
                        (?:([0-9]+(?:\.[0-9]+)?)M)?
                        (?:([0-9]+(?:\.[0-9]+)?)S)?
                    )?\z/x) {
        #require DateTime::Duration;
        #eval { DateTime::Duration->new(years=>$1||0, months =>$2||0, weeks  =>$3||0, days=>$4||0,
        #                               hours=>$5||0, minutes=>$6||0, seconds=>$7||0); 1 }
        #    or die "Invalid duration literal '$v': $@";
        return "require DateTime::Duration && DateTime::Duration->new(years=>".($1||0).", months=>".($2||0).", weeks=>".($3||0).", days=>".($4||0).", hours=>".($5||0).", minutes=>".($6||0).", seconds=>".($7||0).")";
    } elsif (eval { require Time::Duration::Parse::AsHash; $d = Time::Duration::Parse::AsHash::parse_duration($v) } && !$@) {
        return "require DateTime::Duration && DateTime::Duration->new(years=>".($d->{years}||0).", months=>".($d->{months}||0).", weeks=>".($d->{weeks}||0).", days=>".($d->{days}||0).", hours=>".($d->{hours}||0).", minutes=>".($d->{minutes}||0).", seconds=>".($d->{seconds}||0).")";
    } else {
        die "Invalid duration literal '$v'";
    }
}

sub handle_type {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $dt = $cd->{data_term};

    $c->add_module($cd, 'Scalar::Util');
    $cd->{_ccl_check_type} = join(
        '',
        "(",
        "(Scalar::Util::blessed($dt) && $dt->isa('DateTime::Duration'))",
        " || ",
        "(Scalar::Util::looks_like_number($dt) && $dt >= 0)",
        " || ",
        "($dt =~ /\\AP(?:([0-9]+(?:\\.[0-9]+)?)Y)? (?:([0-9]+(?:\\.[0-9]+)?)M)? (?:([0-9]+(?:\\.[0-9]+)?)W)? (?:([0-9]+(?:\\.[0-9]+)?)D)? (?: T (?:([0-9]+(?:\\.[0-9]+)?)H)? (?:([0-9]+(?:\\.[0-9]+)?)M)? (?:([0-9]+(?:\\.[0-9]+)?)S)? )?\\z/x)", # XXX need this? && eval { DateTime::Duration->new(...); 1 }
        " || ",
        "do { my \$d; eval { require Time::Duration::Parse::AsHash; \$d = Time::Duration::Parse::AsHash::parse_duration($dt) }; !\$@ }",
        ")",
    );
}

sub before_all_clauses {
    my ($self, $cd) = @_;
    my $c = $self->compiler;
    my $dt = $cd->{data_term};

    # XXX only do this when there are clauses

    # coerce to DateTime::Duration object during validation
    $self->set_tmp_data_term($cd, $self->expr_coerce_term($cd, $dt))
        if $cd->{has_constraint_clause}; # remember to sync with after_all_clauses()
}

sub after_all_clauses {
    my ($self, $cd) = @_;
    my $c = $self->compiler;
    my $dt = $cd->{data_term};

    $self->restore_data_term($cd)
        if $cd->{has_constraint_clause};
}

1;
# ABSTRACT: perl's type handler for type "duration"

=for Pod::Coverage ^(clause_.+|superclause_.+|handle_.+|before_.+|after_.+|expr_coerce_.+)$

=head1 DESCRIPTION

What constitutes a valid duration value:

=over

=item * L<DateTime::Duration> object

=item * a positive number (of seconds)

=item * string in the form of ISO8601 duration format: "PnYnMnWnDTnHnMnS"

For example: "P1Y2M" (equals to "P14M", 14 months), "P1DT13M" (1 day, 13
minutes).

=back
