# The Valen Programming Language

Valen is a statically-typed, AOT-compiled language that aims to be fast, memory-safe, and flexible.
It uses [group borrowing](https://verdagon.dev/blog/group-borrowing) for memory safety and data-race safety,
allowing mutable aliasing while still guaranteeing correctness.

This guide documents the Valen language as implemented. The language is still a prototype.

## Table of Contents

- [Building a Valen Program](#building-a-valen-program)
- [1. Basics](#1-basics)
  - [Program Structure](#program-structure)
  - [Comments](#comments)
  - [Imports and Modules](#imports-and-modules)
  - [Export](#export)
- [2. Data Types](#2-data-types)
  - [Primitives](#primitives)
  - [Structs](#structs)
  - [Interfaces](#interfaces)
  - [Interface Implementation](#interface-implementation)
  - [Enums (Sealed Interfaces)](#enums-sealed-interfaces)
  - [Tuples](#tuples)
  - [Type Aliases](#type-aliases)
  - [Optionals (Opt)](#optionals-opt)
  - [Result Type](#result-type)
- [3. Functions](#3-functions)
  - [Function Definitions](#function-definitions)
  - [Exported Functions](#exported-functions)
  - [Pure Functions](#pure-functions)
  - [Extern Functions](#extern-functions)
  - [Abstract Functions (Virtual Dispatch)](#abstract-functions-virtual-dispatch)
  - [Overloaded Functions](#overloaded-functions)
  - [Constructors](#constructors)
  - [UFCS (Uniform Function Call Syntax)](#ufcs-uniform-function-call-syntax)
  - [Closures / Lambdas](#closures--lambdas)
  - [Operators Overloading](#operators-overloading)
- [4. Variables and Assignment](#4-variables-and-assignment)
  - [Variable Declaration](#variable-declaration)
  - [Mutable Assignment](#mutable-assignment)
  - [Destructuring](#destructuring)
  - [Move](#move)
  - [Drop](#drop)
  - [Clone](#clone)
- [5. References and Borrowing](#5-references-and-borrowing)
  - [Borrowing (&)](#borrowing-)
  - [Regions](#regions)
  - [Pure Functions and Regions](#pure-functions-and-regions)
  - [Weak References](#weak-references)
- [6. Control Flow](#6-control-flow)
  - [If / Else](#if--else)
  - [While Loops](#while-loops)
  - [Foreach Loops](#foreach-loops)
  - [Break](#break)
  - [Return](#return)
  - [Block Expressions](#block-expressions)
- [7. Arrays](#7-arrays)
  - [Static-Sized Arrays (SSA)](#static-sized-arrays-ssa)
  - [Runtime-Sized Arrays (RSA)](#runtime-sized-arrays-rsa)
  - [Array Operations](#array-operations)
- [8. Generics](#8-generics)
  - [Generic Functions](#generic-functions)
  - [Generic Structs](#generic-structs)
  - [Generic Interfaces](#generic-interfaces)
  - [Where Clauses](#where-clauses)
  - [Kind Parameters](#kind-parameters)
- [9. Downcasting](#9-downcasting)
- [10. Error Handling](#10-error-handling)
- [11. Testing](#11-testing)
- [12. Compiler Annotations](#12-compiler-annotations)

---

## Building a Valen Program

Valen projects are compiled with the `valec build` command. Inputs use the
syntax `name=path` where `name` is a module name and `path` is either a
`.vale` file or a directory containing `.vale` files.

### Prerequisites

The compiler (`valec`) must be built first:

```bash
git clone https://github.com/valen-lang/valen
cd valen
cargo build --bin valec
```

See [BUILD.md](BUILD.md) for detailed build instructions.

### Simple single-file program

Create a file, e.g. `src/main.vale`:

```vale
exported func main() int { 42 }
```

Compile it (run from the repo root so builtins are found):

```bash
./target/release/valec build \
  --builtins-dir-override src/builtins/resources \
  main=src
```

Run the binary:

```bash
./build/main
echo $?   # should output 42
```

### Project with directory structure

Create a project with `src/main.vale`:

```bash
mkdir -p myproject/src
echo 'exported func main() int { 42 }' > myproject/src/main.vale
```

Compile:

```bash
./target/release/valec build \
  --builtins-dir-override src/builtins/resources \
  main=myproject/src
```

### Compiler options

| Option | Description |
|--------|-------------|
| `--output-dir <dir>` | Output directory (default: `build`) |
| `-o <name>` | Executable name (default: `main`) |
| `--builtins-dir-override <dir>` | Path to builtins `.vale` resources |
| `--no-std` | Omit the standard library |
| `-g` | Include debug symbols |
| `--opt-level <level>` | Optimization: `O0`, `O1`, `O2` (default: `O0`) |
| `--verbose` | Print compilation details |
| `--llvm-ir` | Output LLVM IR instead of native binary |
| `--borrow-check` | Enable borrow checking (on by default) |

### Important notes

- Inputs **must** use `name=path` syntax (e.g. `main=src`). The name becomes
  the module/project name.
- The builtins directory (`--builtins-dir-override`) must point to
  `src/builtins/resources` in the valen repo. These provide primitive
  type definitions (`int`, `bool`, `str`, arrays, `Opt`, `Result`, etc.).
- The output directory is deleted and recreated on each build.
- The compiler is still a **prototype**. Some features may not yet work
  correctly, and the borrow checker in particular has known issues.
- Refer to the [test programs](src/tests/programs/) for examples of working
  language constructs.

---

## 1. Basics

### Program Structure

A Valen program consists of `.vale` source files. Programs start execution from an exported `main` function.

```vale
exported func main() int {
  return 42;
}
```

### Comments

```vale
// This is a single-line comment
```

### String Interpolation

Strings support interpolation with `{}`:

```vale
panic("Expected {a} to equal {b}");
println("Argument " + str(i) + " \"" + args[i] + "\" is not an int.")
```

### Imports and Modules

```vale
import v.builtins.arith.*;
import v.builtins.opt.*;
import v.builtins.drop.*;
import stdlib.collections.list.*;
import stdlib.math.*;
import stdlib.stringutils.*;
import stdlib.path.*;
import stdlib.os.*;
```

Wildcard imports use `*`. Nested module paths use `.` as a separator.

### Export

Items can be exported from a module with the `exported` keyword:

```vale
exported func main() int { 0 }
exported struct Path { segments List<str>; }
```

Type aliases can be exported:

```vale
export Array<str> as StrArray;
export Array<str> as MutStrArray;
export List<Path> as PathList;
```

### `print` / `println`

```vale
print("hello");     // print string
print(42);           // print int
print(true);         // print bool
println("hello");    // print with newline
println(42);
```

### Type Conversion

```vale
str(42)       // int → str
str(3.14)     // float → str
str(true)     // bool → str
int(3.14)     // float → int
float(42)     // int → float
i64(42)       // int → i64
```

### Compiler Intrinsics

Certain functions are provided by the compiler:

```vale
__copy_prim(x)    // copy a primitive value
__vbi_panic()     // abort execution
```

### `__pretend` (Unsafe Type Assertion)

```vale
func __pretend<T>() T { __vbi_panic() }
```

This is an unsafe type assertion that never actually runs (it calls panic).
It is used to satisfy the type checker when the programmer knows the type is correct.

---

## 2. Data Types

### Primitives

| Type      | Description             |
|-----------|-------------------------|
| `int`     | 32-bit signed integer   |
| `i64`     | 64-bit signed integer   |
| `i32`     | 32-bit signed integer   |
| `i16`     | 16-bit signed integer   |
| `i8`      | 8-bit signed integer    |
| `u64`     | 64-bit unsigned integer |
| `u32`     | 32-bit unsigned integer |
| `u16`     | 16-bit unsigned integer |
| `u8`      | 8-bit unsigned integer  |
| `usize`   | pointer-sized unsigned  |
| `bool`    | boolean                 |
| `float`   | 32-bit floating point   |
| `str`     | string                  |
| `void`    | unit type / no value    |
| `__Never` | bottom type (for panics)|

```vale
x int = 73;
b bool = true;
f float = 3.14;
s str = "hello";
v void = void();
```

### Structs

Structs group related data. Fields are separated by semicolons.

```vale
struct Marine {
  hp int;
  cool bool;
}
```

Default structs are mutable. The `imm` modifier makes all fields immutable,
and `share` indicates a thread-safe shared struct:

```vale
struct StrSlice imm {
  string str;
  begin int;
  end int;
}

struct Muta share {
  hp int;
}
```

Mutable fields are marked with `!`:

```vale
struct List<E Ref> {
  array! Array<E>;
}
struct IntRangeIter { range &IntRange; i! int; }
```

Structs are constructed with function-call syntax:

```vale
ms = OtherStruct(MyStruct(11));
ms.b.a
```

### Interfaces

Interfaces define abstract behavior:

```vale
interface Error {
  func description(virtual self &Error) str;
  func trace(virtual self &Error) List<Call>;
}

interface MyInterface {
  func doThing(virtual x MyInterface) int;
}
```

Interfaces can be `sealed` (preventing external implementations) and can have
mutability annotations like `share`:

```vale
sealed interface Opt<T> { }
sealed interface MyOption share { }
```

### Interface Implementation

```vale
impl MyInterface for MyStruct;
impl<T> Opt<T> for Some<T>;
impl<OkType, ErrType> Result<OkType, ErrType> for Ok<OkType, ErrType>;
```

### Enums (Sealed Interfaces)

Enums are represented via sealed interfaces with struct variants:

```vale
#!DeriveInterfaceDrop
sealed interface Opt<T> { }

#!DeriveStructDrop
struct Some<T> { value T; }
impl<T> Opt<T> for Some<T>;

#!DeriveStructDrop
struct None<T> { }
impl<T> Opt<T> for None<T>;
```

Upcasting to the enum type:

```vale
x MyInterface = MyStruct(9);
myOpt MyOption<int> = MySome<int>(4);
```

### Tuples

Tuples are anonymous structs with numeric field names:

```vale
t = (true, 42);
t.1  // access second element
```

Predefined tuple types include `Tup0` through `Tup9`:

```vale
struct Tup2<T0, T1> { 0 T0; 1 T1; }
```

### Type Aliases

```vale
export Array<str> as StrArray;
```

### Optionals (Opt)

The `Opt<T>` type represents an optional value. It has two variants:

```vale
Some(42)
None<int>()

isEmpty()  // check if None
get()      // unwrap value (panics on None)
nonEmpty() // returns true if Some
map(func)  // transform inner value
or(func)   // provide default if None
```

Example usage:

```vale
x Opt<int> = Some(42);
if x.isEmpty() {
  // handle None
} else {
  value = x.get();
}
```

### Result Type

`Result<OkType, ErrType>` represents success or failure:

```vale
Ok<int, str>(42)
Err<int, str>("something went wrong")

result.is_ok()      // check if Ok
result.is_err()      // check if Err
result.expect(msg)   // unwrap Ok or panic
result.expect_err(msg) // unwrap Err or panic
```

---

## 3. Functions

### Function Definitions

```vale
func add(a int, b int) int {
  return a + b;
}

func main() {
  // body
}

func len(s StrSlice) int {
  return s.end - s.begin;
}
```

Functions with no return value implicitly return `void`:

```vale
func greet(name str) {
  print("Hello, " + name);
}
```

### Exported Functions

Functions visible outside the module are marked `exported`:

```vale
exported func main() int { 42 }
```

### Pure Functions

Pure functions cannot perform side effects. They are marked with `pure` and
can use region parameters:

```vale
pure func makeArr() StaticArray<2, StaticArray<2, int>> {
  return [#]([#](10, 20), [#](30, 40));
}

pure func pureFunc<r'>(s r'str) bool {
  streq(s, 0, 3, "def", 0, 3)
}
```

### Extern Functions

External (FFI) functions are declared with `extern`:

```vale
extern func __vbi_panic() __Never;
extern func fsqrt(x float) float;

extern func readFileAsString(filenameVStr str) str;
extern func IsWindows() bool;
```

Extern functions can link to a C function with a different name:

```vale
extern("vale_as_subtype")
func try_as<SubType, SuperType, g'>(left &SuperType in g) Result<&SubType, &SuperType>
where implements(SubType, SuperType);
```

### Abstract Functions (Virtual Dispatch)

Abstract functions define an interface contract that each implementor fulfills.
The `virtual` parameter enables dynamic dispatch:

```vale
sealed interface Car {
  func doCivicDance(virtual this Car) int;
}

struct Civic {}
impl Car for Civic;
func doCivicDance(civic Civic) int { return 4; }

struct Toyota {}
impl Car for Toyota;
func doCivicDance(toyota Toyota) int { return 7; }
```

Calling through the interface:

```vale
x Car = Toyota();
return doCivicDance(^x);  // returns 7
```

### Overloaded Functions

Functions can be overloaded by parameter types:

```vale
func bork(a int, b int) int { return a + b; }
func bork(a str, b str) str { return +(a, b); }

func print(s str) { }
func print(i int) { }
func print(b bool) { }

func vassert(cond bool) { }
func vassert(cond bool, msg str) { }
```

### Constructors

A function with the same name as a struct acts as a constructor:

```vale
struct Marine {
  hp int;
  cool bool;
}

func Marine() Marine {
  self.hp = 10;
  self.cool = true;
}
```

### UFCS (Uniform Function Call Syntax)

Any function whose first parameter matches the type can be called as a method:

```vale
func getFuel(a &Spaceship) int {
  return __copy_prim(a.fuel);
}

ship = Spaceship(42);
(&ship).getFuel();  // calls getFuel(&ship)
```

### Closures / Lambdas

Anonymous functions (lambdas) can capture variables from their enclosing scope:

```vale
// Zero-arg lambda returning 42:
{ 42 }

// Lambda with named parameter:
(x) => { print(x); }

// Mutating closure:
x = 10;
({ set x = 42; })();  // calling the lambda
return x;  // returns 42

// Lambdas passed to generic functions:
do(&{ 42 })

// Lambda as array generator:
a = []int(5, &(x) => x * 42);

// Lambda with block body for side effects:
&(chunk) => { print(chunk); }
```

Closures are passed by reference (`&`) when used with generic callable parameters:

```vale
func do<F>(callable &F) int where func(&F)int {
  callable()
}
```

### Operators Overloading

Operators are ordinary functions that can be overloaded:

```vale
func +(a str, b str) str { ... }
func ==(a str, b str) bool { ... }
func <=>(a str, b str) int { ... }
func /(path &Path, segment str) Path { ... }
```

Infix operator calls:

```vale
return 3 bork 3;  // calls bork(3, 3)
```

All arithmetic, comparison, and logical operators are defined as functions:

```vale
+(a, b)    // addition
-(a, b)    // subtraction
*(a, b)    // multiplication
/(a, b)    // division
mod(a, b)  // modulo

==(a, b)   // equality
!=(a, b)   // inequality
<(a, b)    // less than
>(a, b)    // greater than
<=(a, b)   // less or equal
>=(a, b)   // greater or equal
<=>(a, b)  // spaceship (three-way comparison)
===(a, b)  // reference identity

not(b)     // logical NOT
and(a, b)  // logical AND (short-circuit)
or(a, b)   // logical OR (short-circuit)
```

---

## 4. Variables and Assignment

### Variable Declaration

Variables are declared with `name = value`. Type inference is used by default;
an explicit type annotation is optional:

```vale
x = 10;           // inferred int
x int = 73;       // explicit int
b = true;
s = "hello";
```

### Mutable Assignment

The `set` keyword mutates an existing variable or field:

```vale
set x = 42;
set x = x + 1;
set m.hp = 4;
set i = i + 1;
```

`set` returns the old value:

```vale
oldValue = set variable = newValue;
```

### Destructuring

The `^` operator (move) combined with pattern brackets destructures structs and tuples:

```vale
[x] = ^opt;          // destructure struct with one field
[a, b] = ^tup;       // destructure tuple
[value] = ^opt;      // destructure Some variant
[[a1, a2], [a3, a4]] = x;  // nested destructuring
```

### Move

The `^` prefix moves a value, consuming it:

```vale
^opt       // move/destroy opt variant
^value     // move from a local
^x         // move/copy out
```

### Drop

Values are destroyed with `drop`, implemented for each type:

```vale
func drop(x int) {}
func drop(x str) {}
func drop<T>(x &T in g) { }
```

```vale
drop(bork);  // explicitly drop a value
```

The `destruct` statement explicitly discards a value:

```vale
destruct expr;
```

The `unlet` keyword explicitly drops a variable binding.

### Clone

Values can be cloned:

```vale
func clone(x int) int { x }
func clone(x str) str { x }
```

---

## 5. References and Borrowing

### Borrowing (&)

The `&` operator creates an immutable borrow reference:

```vale
carrier = Carrier(400, 8);
ref = &carrier;
// access through reference:
ref.interceptors
```

### Regions

Region parameters (named `g'`, `r'`, etc.) express relationships between
references and their sources. The `in` keyword constrains references to
specific regions:

```vale
func<g'>(s &str in g) int
func<ga', gb'>(a &str in ga, b &str in gb) str
```

Regions allow the borrow checker to distinguish references from different sources:

```vale
abstract func get<T, g'>(virtual opt &Opt<T> in g) &T in g...;
```

### Pure Functions and Regions

Pure functions use region syntax to indicate their parameters are borrowed:

```vale
pure func pureFunc<r'>(s r'str) bool { ... }
pure func Display<r'>(arr &r'StaticArray<2, StaticArray<2, int>>) { ... }
```

### Weak References

Weak references (`&&`) don't keep the value alive. They must be locked (`lock`) to obtain an `Opt<&T>`:

```vale
struct Muta share { hp int; }

ownMuta = Muta(7);
weakMuta = &&ownMuta;                // create weak reference
maybeBorrowMuta = lock(weakMuta);    // lock → Opt<&T>

if maybeBorrowMuta.isEmpty() {
  // value was dropped
} else {
  maybeBorrowMuta.get().hp  // use the borrowed value
}
```

---

## 6. Control Flow

### If / Else

`if/else` is an expression that produces a value:

```vale
result = if (cond) { 42 } else { 73 };

return if (x == 0) {
    1
  } else {
    x * factorial(x - 1)
  };
```

### While Loops

```vale
i = 0;
while i < 10 {
  set i = i + 1;
}
```

### Foreach Loops

```vale
foreach i in range(0, 10) { ... }
foreach flag in flag_list { ... }
foreach segment in path.segments { ... }
foreach a in s.split("/") { ... }
foreach [i, x] in arr.entries() { ... }
foreach [index, element] in list.entries() { ... }
```

Foreach iterates using a `begin`/`next` protocol (similar to Rust's `IntoIterator`).

### Break

```vale
while true {
  if done { break; }
}
```

### Return

```vale
return 42;
return value;
return self.value;
```

### Block Expressions

The `block` keyword creates a scoped block:

```vale
block {
  neighborIndex = 10;
  bork = Bork();
  block {
    drop(bork);
  }
}
```

---

## 7. Arrays

### Static-Sized Arrays (SSA)

Fixed-size arrays with compile-time known length:

```vale
a = [#](23, 31, 37, 42, 49);  // from literal values
a = [#5](&{_ * 42});           // from callable

a.3     // element access (tsugar syntax)
a[3]    // element access (actual AST)

type: StaticArray<2, StaticArray<2, int>>
type: [#5]Flag
type: [#N]<V>T
```

### Runtime-Sized Arrays (RSA)

Dynamic arrays with runtime-determined size:

```vale
a = Array<int>(5, &generator);  // create with generator callable
a = Array<int>(5);              // create empty with capacity
a[3]                             // element access
```

### Array Operations

```vale
len(&arr)           // length
push(&arr, elem)    // add element
pop(&arr)           // remove and return last
capacity(&arr)      // capacity

type: []E           // runtime-sized array of E
type: &[]T          // reference to runtime-sized array

arr.each(func)      // call func on each element
arr.entries()       // returns key-value pair iterator
```

---

## 8. Generics

### Generic Functions

```vale
func identity<T>(x T) T { x }

func getOr<T>(opt &Opt<T>, default &T) &T { ... }

func each<V Variability, N Int, T, F>(arr &[#N]<V>T, func &F) void
where func(&F,&T)void { ... }

func do<F>(callable &F) int where func(&F)int {
  callable()
}
```

### Generic Structs

```vale
struct Some<T> { value T; }
struct MyList<T> where func drop(T)void { value T; next Opt<MyList<T>>; }
struct HashMap<K Ref, V, H, E>
where func(&H, K)int, func(&E, K, K)bool, func drop(K)void { ... }
```

### Generic Interfaces

```vale
sealed interface Opt<T> { }
sealed interface Result<OkType, ErrType> { }
interface IFunction1<M Mutability, P1 Ref, R Ref> M { ... }
```

### Where Clauses

Constraints on type parameters use `where`:

```vale
where func drop(T)void
where func ==(&T, &T)bool
where func(&F, &T)void, func drop(F)void
where func(&H, K)int, func(&E, K, K)bool
where implements(SubType, SuperType)
where T Ref   // T must be a reference type
```

### Kind Parameters

Generic parameters can be constrained by kind, such as `Variability`,
`Int` (for compile-time integers), `Mutability`, and `Ref`:

```vale
func<V Variability, N Int, T, F>(arr &[#N]<V>T, func &F) void
where func(&F,&T)void { ... }

interface IFunction1<M Mutability, P1 Ref, R Ref> M { ... }
```

---

## 9. Downcasting

Downcast from an interface to a concrete type:

```vale
// Borrow downcasting:
maybeRaza Result<&Raza, &IShip> = ship.try_as<Raza>();
if maybeRaza.is_ok() {
  value = maybeRaza.expect("msg").fuel;
}

// Owning downcasting:
maybeRaza Result<Raza, IShip> = (^ship).try_take_as<Raza>();
```

The `try_as` function returns `Result<&SubType, &SuperType>`, and `try_take_as`
returns `Result<SubType, SuperType>`.

---

## 10. Error Handling

Error handling uses the `Result<Ok, Err>` type:

```vale
func Subprocess(command str) Result<Subprocess, str> { ... }
func CreateDir(path &Path, allow_already_existing bool) Result<void, FileError> { ... }
func ListDir(path &Path) Result<List<Path>, FileError> { ... }
```

Result usage pattern:

```vale
result = some_fallible_function();
if result.is_ok() {
  value = result.expect("msg");
} else {
  error = result.expect_err("msg");
}
```

Panics abort the program:

```vale
panic("something went wrong")
__vbi_panic()
```

Assertions:

```vale
vassert(cond);
vassert(cond, "message");
vassertEq(a, b);
```

---

## 11. Testing

The stdlib provides a `TestSuite`:

```vale
suite = TestSuite();
suite.test("name", {
  vassert(something == expected);
  vassert(len("moo" + 16.5) >= len("moo16"));
});
suite.finish();
```

---

## 12. Compiler Annotations

Compiler annotations start with `#!`:

```vale
#!DeriveStructDrop
#!DeriveInterfaceDrop
#!DeriveAnonymousSubstruct
#!DeriveStructConstructor
```

These instruct the compiler to automatically generate implementations for
struct drop, interface drop, anonymous substruct access, or struct constructors.