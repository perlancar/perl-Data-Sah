package Data::Schema::Filters::MyFilter1;

##use Any::Moose;
##extends 'Data::Schema::Filters::Base';

sub filters {
    ['alay'];
}

sub argsch_filter_alay { ['str'] }

sub invoke_filter_alay {
    my ($self, $data) = @_;
    return unless defined($data);
    my %h = (
        y => "ii",
        i => "ee",
        e => 3,
        a => "4",
    );
    my $re = join("|", map {quotemeta} keys %h);
    $data =~ s/($re)/$h{$1}/g;
    $data;
}

sub emitpl_filter_myfilter1 {
    my ($self) = @_;
    my $perl = '';
    $perl .= 'return unless defined($data);'."\n";
    $perl .= 'my %h = ('."\n";
    $perl .= '    y => "ii",'."\n";
    $perl .= '    i => "ee",'."\n";
    $perl .= '    e => 3,'."\n";
    $perl .= '    a => "4",'."\n";
    $perl .= ');'."\n";
    $perl .= 'my $re = join("|", map {quotemeta} keys %h);'."\n";
    $perl .= '$data =~ s/($re)/$h{$1}/g;'."\n";
    $perl .= '$data;'."\n";
    $perl;
}

__PACKAGE__->meta->make_immutable;
##no Any::Moose;
1;
