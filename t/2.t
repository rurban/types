package bar;           # -*- perl -*-
use Test::More tests => 19;
use types;
my int $int;
my number $double;
eval '$int = $number;';
like($@, qr/Type mismatch, can't sassign number \(\$double\) to int \(\$int\)/, 
     "type mismatch int = number");
package foo;
{
    no types;
    eval '$int = $number;';
    use Test::More;
    is($@,"", "no type checking for this lexical scope");
}
package bar;
eval '$int = $number;';
is($@, 'Type mismatch, can\'t sassign number ($double) to int ($int) at (eval 15):1'."\n", 
   "type mismatch int = number - int");
eval '$int = $number = $int;';
is($@, "Type mismatch, can't sassign number (\$double) to int (\$int) at (eval 17):1\n", 
   "Works nested as well");

{
    my int $int = 1;
    eval '$int = 1.2';
    like($@, qr/sassign number \(constant '1.2'\) to int \(\$int\)/, 
	 "Can't sassign number constant to integer" );
    eval '$int = "hi"';
    like($@, qr/sassign string \(constant 'hi'\) to int \(\$int\)/, 
	 "Can't sassign string to integer" );
    my number $double = 2.3;
    eval '$number = 5';
    is($@, "", "Can assign integer constant to number");
    eval '$number = "hi"';
    like($@, qr/assign string \(constant 'hi'\) to number \(\$double\)/, 
	 "Can't assign string to number" );
    my number $number = 2;
    is($number, 2, "Number can be int (constant)");
    $number = 2.5;
    is($number, 2.5, "Number can be number (constant)");
    $number = $int;
    is($number, 1, "Number can be int");
    $number = $number;
    is($number, 5, "Number can number");
    eval '$number = "hi"';
    like($@, qr/assign string \(constant 'hi'\) to number \(\$number\)/, 
	 "Can't assign string to number" );
    
    my string $string = "hi";
    $string = $int;
    is($string, 1, "Int can be assigned to string");
    $string = 20;
    is($string, 20, "Constant int can be assigned to string");
    $string = $number;
    is($string, 5, "Double can be assigned to string");
    $string = 5.5;
    is($string, 5.5, "Constant number can be assigned to string");
    $string = $number;
    is($string, 5, "Number can be assigned to string");
    my $foo = 1;
    $foo = 2.2;
    $foo = "hi";
    pass("Untyped lexicals can still access constant");
}
