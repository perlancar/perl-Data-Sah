package Data::Schema::Config;
# ABSTRACT: Data::Schema configuration

=head1 SYNOPSIS

    # getting configuration
    if ($validator->config->schema_search_path) { ... }

    # setting configuration
    $validator->config->schema_search_path(['.', '/home/steven/schemas']);

=head1 DESCRIPTION

Configuration variables for Data::Schema.

=cut

use Any::Moose;

=head1 ATTRIBUTES

=head2 schema_search_path => ARRAYREF

A list of places to look for schemas. If you use
DSP::LoadSchema::YAMLFile or JSONFile, this will be a list of
directories to search for YAML/JSON files. If you use
DSP::LoadSchema::Hash, this will be the hashes to search for
schemas. This is used if you use schema types (types based on schema).

=cut

has schema_search_path => (is => 'rw', default => sub { ["."] });

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
