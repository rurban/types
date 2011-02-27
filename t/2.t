package bar;
use Test::More tests => 20;
BEGIN { use_ok('types') };
use types;
my int $int;
my double $double;
eval '$int = $double;';
like($@, qr/Type mismatch, can't sassign double \(\$double\) to int \(\$int\)/, "Check that we get type mismatch");
package foo;
{
    no types;
    eval '$int = $double;';
    use Test::More;
    is($@,"", "no type checking for this lexical scope");
}
package bar;
eval '$int = $double;';
is($@, 'Type mismatch, can\'t sassign double ($double) to int ($int) at (eval 15):1'."\n", "Check that we get type mismatch");
eval '$int = $double = $int;';
is($@, "Type mismatch, can't sassign double (\$double) to int (\$int) at (eval 17):1\n", "Workes nested aswell");

{
    my int $int = 1;
    eval '$int = 1.2';
    like($@, qr/sassign double \(constant '1.2'\) to int \(\$int\)/, "Can't sassign double constant to integer" );
    eval '$int = "hi"';
    like($@, qr/sassign string \(constant 'hi'\) to int \(\$int\)/, "Can't sassign string to integer" );
    my double $double = 2.3;
    eval '$double = 5';
    is($@, "", "Can assign integer constant to double");
    eval '$double = "hi"';
    like($@, qr/assign string \(constant 'hi'\) to double \(\$double\)/, "Can't assign string to double" );
    my number $number = 2;
    is($number, 2, "Number can be int (constant)");
    $number = 2.5;
    is($number, 2.5, "Number can be double (constant)");
    $number = $int;
    is($number, 1, "Number can be int");
    $number = $double;
    is($number, 5, "Number can double");
    eval '$number = "hi"';
    like($@, qr/assign string \(constant 'hi'\) to number \(\$number\)/, "Can't assign string to number" );
    
    my string $string = "hi";
    $string = $int;
    is($string, 1, "Int can be assigned to string");
    $string = 20;
    is($string, 20, "Constant int can be assigned to string");
    $string = $double;
    is($string, 5, "Double can be assigned to string");
    $string = 5.5;
    is($string, 5.5, "Constant double can be assigned to string");
    $string = $number;
    is($string, 5, "Number can be assigned to string");
    my $foo = 1;
    $foo = 2.2;
    $foo = "hi";
    pass("Untyped lexicals can still access constant");
}

