# ABSTRACT: Data::Sah developer information
# PODNAME: Data::Sah::Manual::Developer

=pod

=head1 OVERVIEW

=head1 CODE GENERATION

This section will describe how the schema is converted into Perl code.

From each clause, an equivalent Perl expression will be generated (except for a
few special clauses). The expression will return true/false depending on whether
data passes the clause. For example, in the schema:

 ["int", min=>1, max=>10]

the clause C<< min=>1 >> will be translated into something like:

 $data >= 1

and the clause C<< max=>10 >> will be translated into something like:

 $data <= 10

For the type itself (C<int>) we will generate a Perl expression for type
checking:

 Scalar::Util::Numeric::isint($data)

These Perl expressions are then ordered and combined into a single one. The
order follows the priorities specified by the L<Sah> specification, as each
clause has its priority (the lower the number, the higher the priority). The
C<min> and C<max> clauses are "regular" type constraint clauses so they each
have a priority of 50. There is a special clause C<req> (unspecified here, the
default is 0) which have a high priority of 3, which is even higher than the
type check. The C<req> clause, if given the value of 1/true will require data to
be defined. On the other hand, if C<req> is false then if data is undefined then
all the other constraint clauses will be skipped (so C<undef> will pass the
schema).

After the ordering, the type constraint expressions are joined using the Perl
operator C<&&> to be able to shortcut after the first failure. The final Perl
expression becomes:

 (!defined($data) ? 1 :
     (Scalar::Util::Numeric::isnt($data) &&
     ($data >= 1) &&
     ($data <= 10))
 )

=head2 Default value

The C<default> clause is another special clause that has a high priority,
evaluated before C<req>, type check, or the other constraint clauses.

 ["int", min=>1, max=>10, default=>1]

The C<default> clause will be translated into this Perl expression:

 (($data //= 1), 1)

What the above expression does is evaluate the argument to the left of the comma
operator (assigning default value to data) then evaluate the argument to the
right of the comma, then return that value. So the effect is the above
expression will always return true, even though the default value given in the
schema might be false Perl-wise, like C<""> or 0.

So the final expression will become:

 (($data //= 1), 1) &&
 (!defined($data) ? 1 :
     (Scalar::Util::Numeric::isnt($data) &&
     ($data >= 1) &&
     ($data <= 10))
 )

=head2 Required value (req=>1)

What if C<req> is true?

 ["int*", min=>1, max=>10] # a.k.a. ["int", req=>1, min=>1, max=>10]

Then the final expression will become this instead:

 (defined($data) &&
  Scalar::Util::Numeric::isnt($data) &&
  ($data >= 1) &&
  ($data <= 10))

And if we add the default value:

 ["int*", min=>1, max=>10, default=>1]

Then the final expression will become this:

 (($data //= 1), 1) &&
 (defined($data) &&
  Scalar::Util::Numeric::isnt($data) &&
  ($data >= 1) &&
  ($data <= 10))

=head2 Validator subroutine

To generate a validator subroutine, then, is only a matter of adding some bits
to make a full subroutine. Let's get back to this schema:

 ["int", min=>1, max=>10, default=>1]

The final validator code generated would be something like:

 require Scalar::Util::Numeric;
 my $validator = sub {
     my $data = shift;

     (($data //= 1), 1) &&
     (!defined($data) ? 1 :
         (Scalar::Util::Numeric::isnt($data) &&
         ($data >= 1) &&
         ($data <= 10))
     )

 };

This is what is returned by the Data::Sah's C<gen_validator()> function. This
validator will return true when data is valid, or false otherwise. Let's test
it:

 $validator->("x");   # false (fails the type check, isint())
 $validator->(-1);    # false (fails the min clause, $data >= 0)
 $validator->(20);    # false (fails the max clause, $data <= 10)
 $validator->(5);     # true
 $validator->(undef); # true (because there is the default value of 1

=head2 String-returning validator

The above is fine if all you want is a validator that returns true/false (bool).
What if instead you want to return some error message on failure.
gen_validator() supports this: if you pass the option C<< return_type => "str"
>> you will get such validator:

 $validator = gen_validator(["int", min=>1, max=>10, default=>1], {return_type=>"str"});

To do this, each Perl expression will need to be able to set an error message:

 require Scalar::Util::Numeric;
 my $validator = sub {
     my $data = shift;

     my $err_data;

     (($data //= 1), 1) &&
     (!defined($data) ? 1 :
         (Scalar::Util::Numeric::isnt($data) ?      1 : (($err_data //= "Not integer"),0)     ) &&
         ($data >= 1 ?      1 : (($err_data //= "Must be at least 1"),0)     ) &&
         ($data <= 10 ?      1 : (($err_data //= "Must be at most 10"),0)     )
     );

     $err_data //= "";
     $err_data;
 };

So each constraint expression still either returns true or false like in the
boolean validator case, but before the expression returns 0, it sets
C<$err_data> first.

After the whole expression is evaluated, C<$err_data> is returned.

Another possible value for the C<return_type> is C<full>, to return a hash
(instead of a single string) with more information about all the errors and
warnings encountered during validation. It works with the same principle.

=head2 Or-logic

Normally all clauses in a clause set must return true for the validation to
succeed ("and-logic"). However, some other logics are possible: only N clauses
need to succeed, at most N clauses must succeed, or its combination.

When only one clauses need to succeed, this is called an "or-logic". Example
schema for a password policy:

 ["str*", {
     clause => [
         [min_len => 10],
         [match => qr/\W/],
         [match => qr/[A-Z][0-9]|[0-9][A-Z]/i],
     ],
     "clause.op" => "or",
 }]

The above schema says that a password needs to be at least 10 characters long,
I<or> contains a symbol (non-word character), I<or> contains both letters and
numbers.

This will be translated into something like this:

 (defined $data) &&
 (!ref($data)) && # type check for str
 (do {
      my $_sahv_ok = 0;
      my $_sahv_nok = 0;

      (length($data) >= 10                 ? ++$_sahv_ok : ++$_sahv_nok) &&
      ($data =~ qr/\W/                     ? ++$_sahv_ok : ++$_sahv_nok) &&
      ($data =~ qr/[A-Z][0-9]|[0-9][A-Z]/i ? ++$_sahv_ok : ++$_sahv_nok) &&
      $_sahv_ok >= 1;
 })

XXX shortcut after $_sahv_ok becomes 1?

=cut
