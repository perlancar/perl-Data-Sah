package Data::Sah::Compiler::JSONLiteralRole;

use 5.010;
use Moo::Role;

sub literal {
    my ($self, $cd, $val) = @_;

    return $val unless ref($val);

    # for now we use JSON. btw, JSON does obey locale setting, e.g. [1.2]
    # encoded to "[1,2]" in id_ID.
    state $json = do {
        require JSON;
        JSON->new->allow_nonref;
    };

    # we also need cleaning if we use json, since json can't handle qr//, for
    # one.
    state $cleanser = do {
        require Data::Clean::JSON;
        Data::Clean::JSON->new;
    };

    # XXX for nicer output, perhaps say "empty array" instead of "[]", "empty
    # hash" instead of "{}", etc.
    $json->encode($cleanser->clone_and_clean($val));
}

1;
# ABSTRACT: Provide literal() to convert data structure to JSON

=head1 METHODS

=head2 literal() => STR

=cut
