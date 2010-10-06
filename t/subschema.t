#!perl -T
print "0..0\n";
__END__
$ds = new Data::Schema;
invalid(15, {def=>{even=>[int=>{divisible_by=>2}]}, type=>'even', attr_hashes=>[{min=>10}], attrs=>{divisible_by=>3}}, 'third form 1.1', $ds);
valid  (12, {def=>{even=>[int=>{divisible_by=>2}]}, type=>'even', attr_hashes=>[{min=>10}], attrs=>{divisible_by=>3}}, 'third form 1.2', $ds);
dies_ok(sub { $ds->validate(2, 'even') }, 'third form 1.3: "even" is still unknown after previous validation');

valid  ( 2, {def=>{even=>[int=>{divisible_by=>2}], positive_even=>[even=>{min=>0}]},
             type=>'positive_even'}, 'third form 2.1', $ds);
invalid( 1, {def=>{even=>[int=>{divisible_by=>2}], positive_even=>[even=>{min=>0}]},
             type=>'positive_even'}, 'third form 2.2', $ds);
invalid(-2, {def=>{even=>[int=>{divisible_by=>2}], positive_even=>[even=>{min=>0}]},
             type=>'positive_even'}, 'third form 2.3', $ds);
dies_ok(sub {$ds->validate(2, 'even')}, 'third form 2.4: "even" is still unknown after previous validation');
dies_ok(sub {$ds->validate(2, 'even')}, 'third form 2.5: "positive_even" is still unknown after previous validation');

my $sch = {def=>{
                 even=>[int=>{divisible_by=>2}],
                 positive_even=>[even=>{min=>0}],
                 pe=>"positive_even",
                 array_of_pe=>[array=>{of=>'pe'}],
                },
           type=>'array_of_pe'};
invalid(2    , $sch, 'third form 3.1', $ds);
valid  ([]   , $sch, 'third form 3.2', $ds);
valid  ([2]  , $sch, 'third form 3.3', $ds);
invalid([-2] , $sch, 'third form 3.4', $ds);
dies_ok(sub{$ds->validate( 2, 'even')}, 'third form 2.5: "even" is still unknown after previous validation');
dies_ok(sub{$ds->validate( 2, 'positive_even')}, 'third form 2.6: "even" is still unknown after previous validation');
dies_ok(sub{$ds->validate( 2, 'pe')}, 'third form 2.7: "pe" is still unknown after previous validation');
dies_ok(sub{$ds->validate([], 'array_of_pe')}, 'third form 2.8: "array_of_pe" is still unknown after previous validation');

dies_ok(sub{valid(1, {type=>"int", def=>{"int"=>"int"}})}, 'third form: optional definition 1');
valid(1, {type=>"int", def=>{"?int"=>"int"}}, 'third form: optional definition 2');

