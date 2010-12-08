package Sah::Emitter::Perl::Config;
# ABSTRACT: Configuration for Perl emitter of Sah

use Any::Moose;
extends 'Sah::Emitter::ProgBase::Config';

=head1 SYNOPSIS

    # getting configuration
    if ($emitter->config->namespace) { ... }

    # setting configuration
    $emitter->config->namespace('My::Schema');

=head1 DESCRIPTION

See also L<Sah::Emitter::BaseProg::Config>, from which this class is
derived.

=cut

use Any::Moose;

=head1 ATTRIBUTES

=cut

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
