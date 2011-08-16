How perl compiles subs and methods

This was just added to [perloptree.pod](http://beta.metacpan.org/module/perloptree) in **B::C**

Call a subroutine
==============

subname(args...) =>

    pushmark
        args ...
    gv => *subname
    entersub

Call a method
===========

Here we have several combinations to define the package and the method name, either compile-time (static as constant string), or dynamic as **GV** (for the method name) or **PADSV** (package name).

**method_named** holds the method name as **sv** if known at compile time.
If not **gv** (of the name) and **method** is used.
The package name is at the top of the stack.
A call stack is added with **pushmark**.

Static compile time package and method
-----------------------

Class->subname(args...) =>

    pushmark
    const PV => "Class"
        args ...
    method_named => PV "subname"
    entersub

Run-time package and compile-time method
-----------------------

$obj->subname(args...) =>

    pushmark
    padsv => GV *packagename
        args ...
    method_named => PV "subname"
    entersub

Run-time package and run-time method
-----------------------

$obj->$meth(args...) =>

    pushmark
    padsv => GV *packagename
        args ...
    gvsv => GV *meth
    method
    entersub

Compile-time package and run-time method
-----------------------

Class->$meth(args...) =>

    pushmark
    const PV => "Class"
        args ...
    gvsv => GV *meth
    method
    entersub

Possible Optimizations
==================

The purely static case is of course lame and can be massively optimized.
See [http://www.perl.com/pub/2000/06/dougpatch.html](http://www.perl.com/pub/2000/06/dougpatch.html) for the old patch.

The case

Class->subname(args...) =>

    pushmark
    const PV => "Class"
        args ...
    method_named => PV "subname"
    entersub

can be optimized if &Class::subname is defined, otherwise we'd need to ensure a complle-time @ISA with some sort of new method attribute. `:locked` for subs and packages is free. Only a package attribute make sense here really.

The optimization would get rid of the run-time stash lookup for the string "Class", use
the string as first arg to entersub, and the method_named op can be replaced by 
gv => &Class::subname.

    pushmark
        const PV "Class"
        args ...
    gv => *Class::subname
    entersub

Voila, static method calls as fast as function calls, and no ops have to be added.
A similar optimization can be done for typed objects if the object class contains that method, or the found method or defined package is locked.
A Class declaration binds the package to $obj, and can therefore be optimized.

    my Class $obj;
    $obj->method(); # and `&Class::method` is defined, 
           # or sub `Child::method :locked {}`, 
           # or `package Child :locked; `

Easy enough.
