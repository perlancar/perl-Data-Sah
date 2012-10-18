sub test_len($$$$;$) {
    my ($type, $len1, $len2, $len3, $ds) = @_;
    for(qw(minlength minlen min_length minlen)) {
        invalid($len1, [$type => {$_=>2}], "len:$type:$_ 1", $ds);
        valid($len2, [$type => {$_=>2}], "len:$type:$_ 2", $ds);
        valid($len3, [$type => {$_=>2}], "len:$type:$_ 3", $ds);
    }
    for(qw(maxlength maxlen max_length maxlen)) {
        valid($len1, [$type => {$_=>2}], "len:$type:$_ 1", $ds);
        valid($len2, [$type => {$_=>2}], "len:$type:$_ 2", $ds);
        invalid($len3, [$type => {$_=>2}], "len:$type:$_ 3", $ds);
    }
    for(qw(len_between length_between)) {
        valid($len1, [$type => {$_=>[1,2]}], "len:$type:$_ 1", $ds);
        valid($len2, [$type => {$_=>[1,2]}], "len:$type:$_ 2", $ds);
        invalid($len3, [$type => {$_=>[1,2]}], "len:$type:$_ 3", $ds);
    }
    for(qw(len length)) {
        invalid($len1, [$type => {$_=>2}], "len:$type:$_ 1", $ds);
        valid($len2, [$type => {$_=>2}], "len:$type:$_ 2", $ds);
        invalid($len3, [$type => {$_=>2}], "len:$type:$_ 3", $ds);
    }
}
