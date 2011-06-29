Now that I have ["almost"](http://code.google.com/p/perl-compiler/source/detail?r=912) fixed the remaining compiler bugs, I wanted to use the existing framework to enable the possible speedup by using types, esp. low-level internal types. C-style integers and double scalars are used internally in [**B::CC**](http://search.cpan.org/dist/B-C/lib/B/CC.pm) instead of full Perl `IV`'s / `NV`'s if declared as such, and thus greatly improves execution speed. Esp. for inlinable arithmetic and comparison blocks.

Only at the end of such a block (and only when really needed) the calculated C vars are written back to the perl pad. So I needed better [**Opcodes**](http://search.cpan.org/dist/Opcodes) flags to define which ops read or write pads, and more possible optimization hints. Most of these flags should be added to core later, when the time will come to speed up not only the `B::CC` compiler, but also the internal perl compiler.
 
But how to declare types?
=========================

There are two attractive possibilities, and the existing hack. There's also the possibility to use [**Ctypes**](http://gitorious.org/perl-ctypes) to define stricter types (`c_int`), but this would be misleading. Ctypes are for external vars only, not for mix of internal and externals (compiled / uncompiled).

First the hack: 

1. name magic
------------------

Every lexical variable suffixed by "_i", "_d" and an optional "r" (register) suffix are declared as int, double and register (hot, short lived).
This disturbs the namespace and should be possible to disable by a cmdline switch. 

**-fno-name-magic** is the new switch since B-C-1.30 to disable the type specification with the old magic variable names. With perl-5.16 `-fname-magic` will not be selected by default anymore, you'll have to specify it explictily.

2. type classes
------------------

    my int $i; my double $d; 
    my string %hash; my int @array;

Easy readable, but you need to define the `int` and `double` packages in your code, so that perl can parse it.

Luckily there exists a types module already which does compile-time type checking and exactly defines those classes. [**use types;**](http://search.cpan.org/dist/types/) by Artur Bergman from 2002.
Well, float so far, but I will rename it to double.

Compile-time type checking slows down execution in pure perl, but will lead to dramatic performance gains if compiled.
And the good thing: It can also be used to increase pure perl speed by using similar optimizations from B::CC in core also. [i_opt](https://github.com/rurban/perl/tree/i_opt), special CORE flags and faster access for arrays and hashes is the idea.

3. type attributes
---------------------

Type classes are not the full story, we also need type attributes, such as **:readonly** for more massive speedups, and **:unsigned** to specify UV's instead of IV's, and widening the type checks and possible types for stringified vars e.g. such as

    my int $x : string; # PVIV

Using attributes needs to pollute the package namespace with some magic function names. This is a lame design but I think I found the least polluting one (which is certainly not using `Attribute::Handler`).

There is `Readonly`, but this does no performance, only type safety.
`:const` will lead to internal optimizations as done in B::CC, such as not writing back from C to perl, and using special datastructures (perfect hashes, faster and smaller arrays, simplier loops, ...).

use types (the module as planned)
===========================

This pragma does compile-time type checking.

It also permits internal compiler optimizations, and adds type attribute definitions.

SYNOPSIS
-------------

    my double $foo = "string"; #compile time error
    sub foo (int $foo) { my ($foo) = @_ };
    foo("hi"); #compile time Type mismatch error

    my int $int;
    sub foo { my double $foo; return $foo }
    $int = $foo; # compile time Type mismatch error

    my int @array = (0..10); # optimized internal representation
    $array[2] = 2; # no SV, just the raw int at slot 2.

    my int @array :const = (0..10); # even more optimized internal representation
    $array[2] = 2; # int @array is readonly
    $array[2] = '2'; # compile time Type mismatch error

    my string %hash : readonly = (foo => any, bar => any); # optimized gperf representation
    print $hash{foo}; # faster lookup
    $hash{new} = 1;   # compile time Type mismatch error

DESCRIPTION
------------------

This pragma uses the optimize module to analyze the optree and
turns on compile-time type checking.

It is also the base for optimizing compiler passes, for perl CORE (planned)
and for `B::CC` compiled code (done).

Currently we support SCALAR lexicals with the type classes int, double, number, string and user defined classes.

The implicit casting rules are as follows:

    int    < > number
    int      > double
    double < > number
    number   > string


Normal type casting is allowed both up and down the inheritance tree,
so in theory user defined classes should work already, requires one
to do use base or set `@ISA` at compile-time in a BEGIN block.

Implemented are only `SCALAR` types yet, not `ARRAY` nor `HASH`.

ATTRIBUTES
-----------------

Planned type attributes are **:int**, **:double**, **:string**,
**:unsigned**, **:const** and **:readonly**, eventually also **:register** and **:temporary** (as used in the current compiler)

The attributes are perl attributes, and `int|double|string` are either
classes or hint attributes for more allowed types.
If defined as class, compile-time type checks are performed, if as attribute not. Only compiler optimizations are used then.

    my int $i :double;  # declares a NV with SVf_IOK. 
    my $i:int:double;   # same but without type-check
    my int $i;              # declares an IV. 
    my $i:int;             # same but without type-check
    my int $i :string;  # declares a PVIV. An int with allowed stringify and read-as-string.

    my int @array :unsigned = (0..4); 
        # Will be used as c var in faster arithmetic and cmp.
        # Will use no SV value slot, just the direct value.

    my string %hash : readonly = (foo => any, bar => any); 
        # declare string keys only
        # and may be generated as read-only perfect hash.

**:unsigned** is valid for int only and declares an UV. This helps e.g. `i_opt` with bit manip.

**:const** and **:readonly** throw a compile-time error on write access and may
optimize the internal structure of the variable.
E.g. In `CORE` hashes may be optimized to perfect hashes for faster lookup.
Array values for int and double can be optimized (faster accesss, less memory).
In `B::CC` we don't need to write back the variable to perl (lexical write_back).

**:register** denotes optionally a short and hot life-time. for loop
variables are automatically detected as such.

**:temporary** are usually generated internally with nameless lexicals.
They are more aggressivly destroyed and ignored.

STATUS
-----------

`types` has a lot of yet failing dependencies, but I'm working on it. 
Non-core support for `B::Generate` is the worst.

OK (classes only):

    my int $i;
    my double $d;

NOT YET OK (attributes and non-scalars):

    my int $i :register;
    my $i :int;
    my $const :const :int;
    my int $uv :unsigned;

    my int @array;
    my string %hash;
    my int $arrayref = [];
    my int $hashref = {};

Return values
-----------------

Return values are implicitly figured out by the subroutine, this includes
both falling of the end or by expliticly calling return, if two return
values of the same sub differ you will get an error message.

Arguments
-------------

Arguments are declared with prototype syntax, they can either be named
or just typed, if typed only the calling convertions are checked, if
named then that named lexical will get that type without the need
for expliticty typing it, thus allowing list assignment from @_.

Thanks Artur and Malcolm who designed this years ago. 
New will be only type optimizations and attributes, the API is stable since years. 
Just unused.
Time to speed up perl 5.16.

[https://github.com/rurban/types/](https://github.com/rurban/types/)


Implementation ideas
================

Perfect hashes
-------------------

Modern hash functions can nowadays be generated at run-time, leading to perfect hash functions or even minimal perfect hash functions, even for billions of keys.

Hashes declared as **readonly**, such as `my %hash : ro = (key => value, ...);`
or as readonly hashref can be *pre-studied*. 
Which means a dynamic hashing function is generated at run-time using the preferred [BDZ](http://cmph.sourceforge.net/bdz.html) or also called RAM hash function, as implemented under the LGPL in the [cmph library](http://cmph.sourceforge.net/).

Hashes which are generated at run-time benefit from a new op which creates the 
perfect hash function at run-time in RAM also via BDZ.
We will use the existing function **`study %hash;`** or **`study $hashref;`**.

Such perfect hashes can only be generated for uniform key types of course, strings usually. We can decide later if to use the simplier perfect hash, or a stronger and better minimal perfect hash, maybe we will decide this on the hash size.

Space and time costs for the generation and final storage of a BDZ function are linear, O(n) bits for the generation step, 1bit per key for the generated hash function, 
lookup is O(1) (*no collisions*), see the [detailed analysis](http://cmph.sourceforge.net/papers/thesis.pdf).

Of course for the compiler with readonly hashes we can think of using **gperf**, 
which needs much longer and cannot be used at run-time, but generates better and smaller hash functions. 
Heck we don't even use good hashes for generated XS constants yet, only `Win32::GUI` does. 


Typed arrays
-----------------

A typed array such as `my int @array;` uses uniform types for the values not the typed keys as for perfect hashes. An array key is always an int.
We can use the existing `AvARRAY` buffer, just with direct access to the value slot. 
We need no SV indirection, which saves time and space.
We will need a new `AvTYPED` flag and either restrict to IOK, NOK and POK, or add 
a xpvav slot for a broader type declaration. 

The implementation is straightforward.

Links
-------
[http://perl.plover.com/classes/typing/](http://perl.plover.com/classes/typing/)

[http://search.cpan/dist/types](http://search.cpan/dist/types)

[http://search.cpan/dist/typesafety](http://search.cpan/dist/typesafety)

[http://search.cpan.org/dist/Moose/lib/Moose/Manual/Types.pod](http://search.cpan.org/dist/Moose/lib/Moose/Manual/Types.pod)

