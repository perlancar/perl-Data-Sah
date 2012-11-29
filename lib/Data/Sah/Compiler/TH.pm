package Data::Sah::Compiler::TH;

use 5.010;
use Moo;

# VERSION

# reference to compiler object
has compiler => (is => 'rw');

sub clause_v {
    my ($self, $cd) = @_;
    $self->compiler->_ignore_clause($cd);
}

sub clause_default_lang {
    my ($self, $cd) = @_;
    $self->compiler->_ignore_clause($cd);
}

sub clause_clause {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $cv = $cd->{cl_value};

    # XXX should we execute before_clause() and after_clause() for the specified
    # clause?

    my $clause = $cv->[0];
    my $meth   = "clause_$clause";
    my $mmeth  = "clausemeta_$clause";

    local $cd->{clause}  = $clause;
    unless ($self->can($meth)) {
        given ($cd->{args}{on_unhandled_clause}) {
            0 when 'ignore';
            do { warn "Can't handle clause $clause"; return }
                when 'warn';
            $c->_die($cd, "Can't handle clause $clause");
        }
    }

    # put information about the clause to $cd

    # for a complete illusion to the clause handler, that it is actually
    # handling clause $clause.
    my $orig_clset = $cd->{clset};
    local $cd->{clset} = {};
    for (keys %$orig_clset) {
        next if /\A\Q$clause(\.|\z)/;
        $cd->{clset}{$_} = $orig_clset->{$_};
    }
    $cd->{clset}{$clause} = $cv->[1];

    my $meta;
    if ($self->can($mmeth)) {
        $meta = $self->$mmeth;
    } else {
        $meta = {};
    }
    local $cd->{cl_meta}    = $meta;
    local $cd->{cl_value}   = $cv->[1];
    local $cd->{cl_term}    = $c->literal($cv->[1]);
    local $cd->{cl_is_expr} = 0;
    local $cd->{cl_op};

    $self->$meth($cd) if $self->can($meth);
}

1;
# ABSTRACT: Base class for type handlers

=for Pod::Coverage ^(compiler|clause_.+)$

=cut
