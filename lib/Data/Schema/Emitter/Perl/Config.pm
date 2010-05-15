package Data::Schema::Emitter::Perl::Config;
# ABSTRACT: Configuration for Perl emitter of Data::Schema

use Any::Moose;
extends 'Data::Schema::Emitter::ProgBase::Config';

=head1 SYNOPSIS

    # getting configuration
    if ($emitter->config->namespace) { ... }

    # setting configuration
    $emitter->config->namespace('My::Schema');

=cut

use Any::Moose;

=head1 ATTRIBUTES

See L<Data::Schema::Emitter::ProgBase::Config>.

=cut

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
