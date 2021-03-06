# NAME

Class::LOP - The Lightweight Object Protocol 

# DESCRIPTION

Just like [Moose](https://metacpan.org/pod/Moose) is built from [Class::MOP](https://metacpan.org/pod/Class::MOP). You can build your own using this module. It is a little different 
from [Class::MOP](https://metacpan.org/pod/Class::MOP) though, because it doesn't use a meta class, it has less features, but it's a lot faster.
If you need something lightweight, this may be the tool for you.
Using this module you could build an extremely quick OOP framework that could be used from a CLI or as a standard 
module. Alternatively, just use it to import extra features into modules. Like everything in Perl, it's all up to you!

# SYNOPSIS

```perl
package Goose;

use Class::LOP;

sub import {

    my $caller = caller();
    # Methods can be chained for simplicity and easy tracking.
    # Below, we'll create the 'new' constructor, enable warnings and strict, and also
    # bestow the accessors feature, so our module can create them
    Class::LOP->init($caller)
        ->create_constructor
        ->warnings_strict
        ->have_accessors('has');

    # import multiple methods into the specified class
    Class::LOP->init('Goose')->import_methods($caller, qw/
        extends
        after
        before
    /);
}

# Add a few hook modifiers
# This code sure looks a lot cleaner than writing it yourself ;-)
sub after {
    my ($name, $code) = @_;

    Class::LOP->init(caller())->add_hook(
        type  => 'after',
        name => $name,
        method   => $code,
    );
}

# Extending a class is similar to 'use base'
# You may have also seen this from Moose
# ->extend_class() makes it really easy for you
sub extends {
    my (@classes) = @_;
    Class::LOP->init(caller())
        ->extend_class(@classes);
}

# MyClass.pm
package MyClass;

use Goose; # enables warnings/strict
extends 'Some::Module::To::Subclass';

has 'name' => ( is => 'rw', default => 'Foo' );

after 'name' => sub {
    print "This code block runs after the original!\n";
};
```

Wow, that all looks familiar.. but we wrote it all in a fairly small amount of code. Class::LOP takes care of the 
dirty work for you, so you can just worry about getting the features in your module that you want.

# METHODS

## init

Initialises a class. This won't create a new one, but will set the current class as the one specified, if it 
exists.
You can then chain other methods onto this, or save it into a variable for repeated use.

```
Class::LOP->init('SomeClass');
```

## new

Initialises a class, but will also create a new one should it not exist. If you're wanting to initialise a class 
you know exists, you're probably better off using `init`, as it involves less work.

```perl
Class::LOP->new('MyNewClass')
    ->create_method('foo', sub { print "foo!\n" });

my $class = MyNewClass->new();
$class->foo(); # prints foo!
```

Using `new` then chaining `create_method` onto it, we were able to create a class and a method on-the-fly.

## warnings\_strict

Enables `use warnings` and `use strict` pragmas in Class::LOP modules

```
$class->warnings_strict();
```

## getscope

Basically just a `caller`. Use this in your modules to return the class name

```perl
my $caller = $class->getscope();
```

## class\_exists

Checks to make sure the class has been imported

```perl
use Some::Module;

if ($class->class_exists()) {
    print "It's there!\n";
}
```

## method\_exists

Detects if a specific method in a class exists

```
if ($class->method_exists($method_name)) { .. }
```

## subclasses

Returns an list of subclassed modules

```perl
my @subclass_mods = $class->subclasses();
for (@subclass_mods) {
    print "$_\n";
}
```

## superclasses

Returns a list of superclass (base) modules

```perl
my @superclass_mods = $class->superclasses();
for (@superclass_mods) {
    print "$_\n";
}
```

## import\_methods

Injects existing methods from the scoped module to a specified class

```
$class->import_methods($destination_class, qw/this that and this/);
```

Optionally, `import_methods` can return errors if certain methods don't exist. You can read these 
errors with `last_errors`. This is only experimental at the moment.

## extend\_class

Pretty much the same as `use base 'Mother::Class'`. The first parameter is the subclass, and the following array 
will be its "mothers".

```perl
my @mommys = qw(This::Class That::Class);
$class->extend_class(@mommys)
```

## have\_accessors

Adds Moose-style accessors to a class. First parameter is the class, second will be the name of the method to 
create accessors.

```perl
# Goose.pm
$class->have_accessors('acc');

# test.pl
use Goose;

acc 'x' => ( is => 'rw', default => 7 );
```

Currently the only two options is `default` and `is`.

## create\_constructor

Simply adds the `new` method to your class. I'm wondering whether this should be done automatically? The 
aim of this module is to give the author as much freedom as possible, so I chose not to.

```
$class->create_constructor;
```

## create\_method

Adds a new method to an existing class.

```perl
$class->create_method('greet', sub {
    my $self = shift;
    print "Hello, World from " . ref($self) . "\n";
});

MooClass->greet();
```

## add\_hook

Adds hook modifiers to your class. It won't import them all - only use what you need :-)

```perl
$class->add_hook(
    type  => 'after',
    method => $name,
    code   => $code,
);
```

The types are `after`, `before`, and `around`.

## list\_methods

Returns a list of all the methods within an initialised class. It will filter out classes

```perl
my @methods = Class::LOP->init('SomeClass')->list_methods();
```

## clone\_object

Takes an object and spits out a clone of it. This means mangling the original will have no side-effects to the cloned one
I know [DateTime](https://metacpan.org/pod/DateTime) has its own `clone` method, but still, it's a good example.

```perl
my $dt = DateTime->now;
my $dt2 = Class::LOP->init($dt)->clone_object;

print $dt->add(days => 5)->dmy() . "\n";
print $dt2->dmy() . "\n";
```

Simply changing `$dt2 = $dt` would mean both results would have the same date when we printed them, but because we cloned the object, they are separate.

## override\_method

Unlike `create_method`, this method will let you replace the existing one, thereby overriding it.

```perl
sub greet { print "Hello\n"; }

Class::LOP->init('ClassName')->override_method('greet', sub { print "Sup\n" });

greet(); # prints Sup
```

## call\_super

Will run any methods with the same name from super classes.

```perl
use base 'Some::Class';

sub some_method {
    # will call Some::Class::some_method(@_)
    Class::LOP->init(__PACKAGE__)
        ->call_super(@_);
}
```

## load\_namespaces

Will import all modules within the initialised class' namespace. For example, say we 
have a class called `MyClass`. And within `@INC` we have `MyClass::Test`, `MyClass::Test::Testing`. 
Calling this... 

```
Clas::LOP->init('MyClass')->load_namespaces();
```

... would load all of the modules listed, because they are all within the same namespace.

# AUTHOR

Brad Haywood <brad@perlpowered.com>

# LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.
