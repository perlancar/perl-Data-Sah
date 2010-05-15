package Data::Schema::Plugin::LoadSchema::Base;
# ABSTRACT: Base class for other DSP::LoadSchema::* plugins

use Any::Moose;
use Log::Any qw($log);

=head1 SYNOPSIS

    # see other DSP::LoadSchema::* plugins

=head1 ATTRIBUTES

=head2 main

=cut

has 'main' => (is => 'rw');

=head1 METHODS

=cut

=head2 get_it($name)

Return the schema specified by C<$name>, or C<undef> if not found. To
be overriden by subclass.

=cut

sub get_it {
    return;
}

sub hook_unknown_type {
    my ($self, $name) = @_;

    my $schema = $self->get_it($name);
    return -1 unless defined($schema);
    $self->main->register_schema($schema, $name);
    1;
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
