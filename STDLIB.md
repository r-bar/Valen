# Valen Standard Library Reference

The Valen standard library provides the core types and functions for everyday programming.
Each module is documented below with its types, functions, and usage examples.

## Table of Contents

- [Builtins](#builtins--core-language-types)
- [collections.list](#collectionslist--dynamic-list)
- [collections.hashmap](#collectionshashmap--hash-map)
- [collections.hashset](#collectionshashset--hash-set)
- [arrays](#arrays--array-helpers)
- [str](#str--string-slice-and-operations)
- [stringutils](#stringutils--string-utility-functions)
- [cast](#cast--type-concatenation-helpers)
- [print](#print--output-functions)
- [panic](#panic--assertions-and-abort)
- [logic](#logic--boolean-operations)
- [math](#math--mathematical-utilities)
- [optutils](#optutils--optional-helpers)
- [resultutils](#resultutils--result-helpers)
- [error](#error--error-interface)
- [command](#command--subprocess-spawning)
- [path](#path--filesystem-path-manipulation)
- [flagger](#flagger--command-line-flag-parsing)
- [ifunction](#ifunction1--single-parameter-function-interface)
- [date](#date--unix-timestamp)
- [mtpid](#mtpid--micro-time-process-id)
- [os](#os--operating-system-queries)
- [stdin](#stdin--standard-input)
- [testsuite](#testsuite--unit-test-framework)

---

## `builtins` — Core Language Types

The builtins module provides the primitive types, core data structures (Opt,
Result, tuples), and fundamental operations (arithmetic, comparison, drop,
clone) that the language depends on. Builtins are automatically included in
every Valen program from the `src/builtins/resources` directory (pointed to
via `--builtins-dir-override`).

Builtins are imported with the `v.builtins.*` prefix:

```vale
import v.builtins.arith.*;
import v.builtins.opt.*;
import v.builtins.result.*;
import v.builtins.drop.*;
import v.builtins.clone.*;
import v.builtins.logic.*;
import v.builtins.str.*;
import v.builtins.panic.*;
import v.builtins.arrays.*;
import v.builtins.streq.*;
```

### Primitive Types

The compiler provides these primitive types, defined as builtin kinds:

```vale
int     // 32-bit signed integer
i64     // 64-bit signed integer
bool    // boolean
float   // 32-bit floating point
str     // string
void    // unit type (absence of value)
__Never // bottom type (for panics/abort)
```

### Arithmetic (`arith`)

Arithmetic and comparison operators on primitives:

```vale
+(a int, b int) int        // addition
-(a int, b int) int        // subtraction
*(a int, b int) int        // multiplication
/(a int, b int) int        // division
mod(a int, b int) int      // modulo

-(x int) int               // negation

==(a int, b int) bool      // equality
!=(a &T, b &T) bool        // inequality
<(a int, b int) bool       // less than
>(a int, b int) bool       // greater than
<=(a int, b int) bool      // less or equal
>=(a int, b int) bool      // greater or equal

// Same operations exist for i64, float, and bool types.
// Generic region-parameterized variants exist, e.g.:
// func +<gl', gr'>(left &int in gl, right &int in gr) int
```

Type conversion arithmetic:

```vale
float(x &int) float        // int → float
int(x &float) int          // float → int
i64(x &int) i64            // int → i64
float(i64)(x &i64) float   // i64 → float (via builtin)
```

### String Operations (`str`)

```vale
str(x int) str             // int to string
str(x i64) str             // i64 to string
str(x float) str           // float to string

+(a &str, b &str) str      // string concatenation
len(s &str) int            // string length

strtoascii(s &str, begin int, end int) int   // char to ASCII code
strfromascii(code int) str                    // ASCII code to string

strindexof(haystack, hBegin, hEnd, needle, nBegin, nEnd) int  // find substring
substring(str, begin, end) str                                 // extract substring

strcmp(a, aBegin, aEnd, b, bBegin, bEnd) int  // lexicographic cmp
```

### String Equality (`streq`)

```vale
streq(a, aBegin, aEnd, b, bBegin, bEnd) bool  // string equality by slices
extern func __vbi_streq(...) bool
```

### Boolean Logic (`logic`)

```vale
not(b bool) bool                             // logical NOT
==(left bool, right bool) bool               // boolean equality
!=<T, ga', gb'>(a &T, ga; b &T, gb) bool    // inequality
```

### `Opt<T>` — Optional Value (`opt`)

The `Opt<T>` sealed interface provides nullable values with two variants:

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

Abstract functions and their concrete implementations:

```vale
// Drop
abstract func drop<T>(virtual opt Opt<T>) where func drop(T)void;
func drop<T>(opt Some<T>) where func drop(T)void { [x] = ^opt; }
func drop<T>(opt None<T>) { [ ] = ^opt; }

// isEmpty — check for None
abstract func isEmpty<T, g'>(virtual opt &Opt<T> in g) bool;
func isEmpty<T, g'>(opt &None<T> in g) bool { return true; }
func isEmpty<T, g'>(opt &Some<T> in g) bool { return false; }

// get — unwrap (panics on None)
abstract func get<T>(virtual opt Opt<T>) T;
func get<T>(opt None<T>) T { panic("Called get() on a None!"); }
func get<T>(opt Some<T>) T { [value] = ^opt; return ^value; }

// get with group borrowing
abstract func get<T, g'>(virtual opt &Opt<T> in g) &T in g...;
func get<T, g'>(opt &None<T> in g) &T in g... { panic("Called get() on a None!"); }
func get<T, g'>(opt &Some<T> in g) &T in g... { return &opt.value; }
```

### `Result<OkType, ErrType>` — Success or Failure (`result`)

```vale
#!DeriveInterfaceDrop
sealed interface Result<OkType, ErrType> { }

#!DeriveStructDrop
struct Ok<OkType, ErrType> { value OkType; }
impl<OkType, ErrType> Result<OkType, ErrType> for Ok<OkType, ErrType>;

#!DeriveStructDrop
struct Err<OkType, ErrType> { value ErrType; }
impl<OkType, ErrType> Result<OkType, ErrType> for Err<OkType, ErrType>;
```

Abstract functions:

```vale
abstract func is_ok<OkType, ErrType, g'>(virtual result &Result<O,E> in g) bool;
func is_ok<O,E,g'>(ok &Ok<O,E> in g) bool { return true; }
func is_ok<O,E,g'>(err &Err<O,E> in g) bool { return false; }
func is_err<O,E,g'>(result &Result<O,E> in g) bool { return not is_ok(result); }

abstract func expect<O,E>(virtual result Result<O,E>, msg str) O;
func expect<O,E>(err Err<O,E>, msg str) O { panic(msg); }
func expect<O,E>(ok Ok<O,E>, msg str) O { [value] = ^ok; return ^value; }

abstract func expect_err<O,E>(virtual result Result<O,E>, msg str) E;
func expect_err<O,E>(ok Ok<O,E>, msg str) E { panic("expect_err on Ok!"); }
func expect_err<O,E>(err Err<O,E>, msg str) E { [value] = ^err; return ^value; }

// Borrow variants with groups
abstract func expect<O,E,g'>(virtual result &Result<O,E> in g, msg str) &O in g...;
abstract func expect_err<O,E,g'>(virtual result &Result<O,E> in g, msg str) &E in g...;
```

### Drop (`drop`)

Destructors for primitive types and generic references:

```vale
func drop(x int) {}
func drop(x bool) {}
func drop(x float) {}
func drop(x void) {}
func drop(x i64) {}
func drop(x str) {}
func drop<T, g'>(x &T in g) { }

func drop<T>(v void, x T) where func drop(T)void { drop(^x) }
```

### Clone (`clone`)

```vale
func clone(x int) int { x }
func clone(x bool) bool { x }
func clone(x float) float { x }
func clone(x void) { }
func clone(x i64) i64 { x }
func clone(x str) str { x }

// Borrow variants for post-kind-mutability-cut where clauses:
func clone<g'>(x &int in g) int { __copy_prim(x) }
func clone<g'>(x &bool in g) bool { __copy_prim(x) }
func clone<g'>(x &float in g) float { __copy_prim(x) }
func clone<g'>(x &i64 in g) i64 { __copy_prim(x) }
```

### Implicit Clone (`implicit_clone`)

Used internally by the type system for automatic copies of primitives:

```vale
func implicit_clone<g'>(x &int in g) int { return __copy_prim(x); }
func implicit_clone<g'>(x &bool in g) bool { return __copy_prim(x); }
func implicit_clone<g'>(x &float in g) float { return __copy_prim(x); }
func implicit_clone<g'>(x &void in g) void { }
func implicit_clone<g'>(x &i64 in g) i64 { return __copy_prim(x); }
```

### Downcast (`as`)

Downcast from an interface to a concrete subtype:

```vale
// Borrow downcast — returns Result<&SubType, &SuperType>
extern("vale_as_subtype")
func try_as<SubType, SuperType, g'>(left &SuperType in g) Result<&SubType, &SuperType>
where implements(SubType, SuperType);

// Owning downcast — returns Result<SubType, SuperType>
extern("vale_as_subtype")
func try_take_as<SubType, SuperType>(left SuperType) Result<SubType, SuperType>
where implements(SubType, SuperType);
```

### Reference Identity (`sameinstance`)

```vale
extern("vale_same_instance")
func ===<T, gl', gr'>(left &T in gl, right &T in gr) bool;
```

### Weak References (`weak`)

```vale
extern("vale_lock_weak")
func lock<T>(w weak T) Opt<&T>;
```

### Panic (`panic`)

```vale
extern func __vbi_panic() __Never;

func panic() __Never { return __vbi_panic(); }
func panic(msg str) __Never {
  print(&msg);
  print(&"\n");
  return __vbi_panic();
}
```

### Print (`print`)

```vale
func print<g'>(s &str in g) { __vbi_printstr(s, 0, len(s)) }
extern func __vbi_printstr<g'>(s &str in g, start int, length int);
```

### Tuples (`tup0`–`tupN`)

Pre-defined tuple types with numeric-indexed fields:

```vale
struct Tup0 { }
#!DeriveStructDrop
struct Tup1<T0> { 0 T0; }
#!DeriveStructDrop
struct Tup2<T0, T1> { 0 T0; 1 T1; }
#!DeriveStructDrop
struct Tup3<T0, T1, T2> { 0 T0; 1 T1; 2 T2; }
```

Tuples are constructed with parentheses:

```vale
t = (true, 42);       // type Tup2<bool, int>
t.1                    // access second element → 42
```

### Functor1 (`functor1`)

Default callable trampoline for zero-argument void-return lambdas:

```vale
func __call<P1, R>(v void, param P1) R
where func drop(P1)R { drop(^param) }
```

### Arrays (`arrays`)

Array builtins (externals to the C++ backend):

```vale
// Static-sized array:
len<S Int, E, g'>(arr &StaticArray<S, E> in g) int
drop_into<S Int, E, F, g'>(arr StaticArray<S, E>, consumer &F in g) void
drop<S Int, E>(arr StaticArray<S, E>) void where func drop(E)void

// Runtime-sized array:
Array<E>(size int) []E
push<E, g'>(arr &[]E in g, newElement E) void
pop<E, g'>(arr &[]E in g) E
len<E, g'>(arr &[]E in g) int
capacity<E, g'>(arr &[]E in g) int
drop<E>(arr []E) void where func drop(E)void

// Array with generator callable:
Array<E, G, g'>(n int, generator &G in g) []E
where func(&G, int)E, func drop(G)void
```

### Main Args (`mainargs`)

Access command-line arguments:

```vale
extern func numMainArgs() int;
func getMainArg(i int) str
```

### Migrate (`migrate`)

Move elements between arrays (currently stubbed):

```vale
func migrate<E, g'>(from []E, to &[]E in g) void
func migrate<E, N Int, g'>(from StaticArray<N, E>, to &[]E in g) void
```

### Compiler Intrinsics

Certain functions are provided directly by the compiler:

```vale
__copy_prim(x)     // copy a primitive value
__vbi_panic()      // abort execution (__Never return)
__vbi_printstr(s, start, length)  // raw string output
__vbi_addStr(a, aBegin, aLen, b, bBegin, bLen) str  // string concat
__vbi_strLength(s) int    // string length
__vbi_streq(...) bool     // string equality
__vbi_strtoascii(...) int // char to ASCII
__vbi_strfromascii(int) str // ASCII to char
__vbi_strindexof(...) int // substring index
__vbi_substring(...) str  // substring extraction
__vbi_strcmp(...) int     // string comparison
__vbi_addI32(a, b) int    // 32-bit addition
__vbi_negateI32(x) int    // 32-bit negation
__vbi_multiplyI32(...) int // etc.
```

A generic, dynamically-growable list backed by an `Array<E>`. Provides element
access, search, iteration, functional combinators, and conversion to/from
static arrays.

### All-in-One Example

```vale
import * from stdlib.collections.list

// Creation
people = List<str>();
people.add("Alice");
people.add("Bob");
people.add("Charlie");

// Length
println(len(people));  // 3

// Get by index
println(people.get(0));  // Alice
println(people.get(1));  // Bob

// Contains
println(people.contains("Bob"));  // true

// Remove by index
removed = people.remove(1);
println(removed);  // Bob

// Join
println(people.join(", "));  // Alice, Charlie

// Iteration
foreach p in people {
  println(p);
}

// Indexed iteration
foreach [i, p] in people.entries() {
  println(str(i) + ": " + p);
}

// Map
lengths = people.map(&(s) => s.len());

// To array
arr = people.toArray();
```

### Types

#### `List<E Ref>`

```vale
struct List<E Ref> {
  array! Array<E>;
}
```

A dynamic list storing elements in a growable `Array<E>`. `E` must be a
reference type. The internal array doubles in capacity when full.

#### `ListIter<E>` and `ListEntriesIter<E>`

```vale
struct ListIter<E> where E Ref {
  list_array &Array<E>;
  pos! int;
}

struct ListEntriesIter<E> where E Ref {
  list_array &Array<E>;
  pos! int;
}
```

Iterators for `foreach`. `ListIter` yields `&E`; `ListEntriesIter` yields
`(int, &E)` pairs.

### Constructors

```vale
List<E>()                    // empty list
List<E>(capacity int)        // pre-allocated capacity
List<E>(arr [#N]<V>E)        // from static array
```

### Functions

| Function | Signature | Description |
|----------|-----------|-------------|
| `len` | `(list &List<E>) int` | Number of elements |
| `add` | `(list &List<E>, newElement E) void` | Append element |
| `get` | `(list &List<E>, index int) &E` | Get element reference |
| `set` | `(list &List<E>, index int, value E) E` | Replace at index, returns old |
| `remove` | `(list &List<E>, removeAtIndex int) E` | Remove and return element |
| `indexOf` | `(list &List<E>, element &E) Opt<int>` | Find first matching index |
| `indexWhere` | `(list &List<E>, func &F) Opt<int>` | Find index by predicate |
| `contains` | `(list &List<E>, element &E) bool` | Check membership |
| `reverse` | `(list List<E>) List<E>` | Reversed copy |
| `exists` | `(list &List<E>, func &F) bool` | Any element matches predicate |
| `each` | `(list &List<E>, func &F) void` | Call on each element |
| `map` | `(list &List<E>, func &F) List<T>` | Transform each element |
| `toArray` | `(list List<E>) []E` | Consume into array |
| `toArray` | `(list &List<E>) []&E` | References to array |
| `clone` | `(list &List<E>) List<E>` | Deep copy |
| `join` | `(list &List<str>) str` | Concatenate strings |
| `join` | `(list &List<str>, joiner str) str` | Concatenate with separator |

### Iteration

```vale
foreach x in list { }
foreach [i, x] in list.entries() { }
```

---

## `collections.hashmap` — Hash Map

A generic hash map (dictionary) associating unique keys of kind `K Ref` with
values of any type `V`. Requires two strategy objects:

| Parameter | Required signature |
|-----------|--------------------|
| `H`       | `func(&H, K) int` |
| `E`       | `func(&E, K, K) bool` (equality) |

Built-in hasher/equator pairs:
- `IntHasher` / `IntEquator` from `math`
- `StrHasher` / `StrEquator` from `stringutils`

### All-in-One Example

```vale
import * from stdlib.math
import * from stdlib.collections.hashmap

// Create with IntHasher / IntEquator
map = HashMap<int, str, IntHasher, IntEquator>(
    IntHasher(), IntEquator());

map.add(1, "one");
map.add(2, "two");
map.add(3, "three");

// Look up by key
v1 = map.get(1);      // Some<&str>
println(v1.isEmpty());  // false

// Check containment
println(map.ContainsKey(2));  // true
println(map.ContainsKey(4));  // false

// Update existing key (returns old value)
old = map.update(1, "uno"); // "one"

// Remove key (returns old value)
removed = map.remove(2);

// Collect keys
ks = map.keys();

// Use StrHasher/StrEquator
import * from stdlib.stringutils
smap = HashMap<str, int, StrHasher, StrEquator>(
    StrHasher(), StrEquator());
smap.add("x", 10);
```

### Functions

| Function | Signature | Description |
|----------|-----------|-------------|
| `len` | `(self &HashMap<K,V,H,E>) int` | Number of entries |
| `add` | `(map &HashMap<K,V,H,E>, key K, value V) void` | Insert entry |
| `get` | `(self &HashMap<K,V,H,E>, key K) Opt<&V>` | Look up key |
| `ContainsKey` | `(self &HashMap<K,V,H,E>, key K) bool` | Key exists? |
| `update` | `(self &HashMap<K,V,H,E>, key K, value V) V` | Replace value, returns old |
| `remove` | `(map &HashMap<K,V,H,E>, key K) V` | Remove entry, returns value |
| `keys` | `(self &HashMap<K,V,H,E>) Array<K>` | All keys |
| `values` | `(self &HashMap<K,V,H,E>) Array<&V>` | All value references |

---

## `collections.hashset` — Hash Set

A generic hash set with open-addressing (linear probing). Supports iteration
via `foreach`, equality comparison, set difference, and conversion.

### All-in-One Example

```vale
import * from stdlib.math
import * from stdlib.collections.hashset

// Create an empty set
sett = HashSet<int, IntHasher, IntEquator>(IntHasher(), IntEquator())

sett.add(10)
sett.add(20)
sett.add(30)

println(sett.len())         // 3
println(sett.contains(20))  // true
println(sett.contains(99))  // false

sett.remove(20)
println(sett.len())         // 2

// Convert to List
list = List(&sett)

// Convert to Array
arr = sett.toArray()

// Equality
other = HashSet<int, IntHasher, IntEquator>(IntHasher(), IntEquator())
other.add(10).add(30)
println(&sett == &other)    // true

// Random element
elem = sett.GetRandomElement(42)
```

### Functions

| Function | Signature | Description |
|----------|-----------|-------------|
| `len` | `(self &HashSet<K,H,E>) int` | Number of elements |
| `isEmpty` | `(self &HashSet<K,H,E>) bool` | Set is empty? |
| `add` | `(self &HashSet<K,H,E>, key K) void` | Insert key |
| `get` | `(self &HashSet<K,H,E>, key K) Opt<K>` | Retrieve key ref |
| `contains` | `(self &HashSet<K,H,E>, key K) bool` | Key exists? |
| `remove` | `(self &HashSet<K,H,E>, key K) void` | Remove key |
| `toArray` | `(self &HashSet<K,H,E>) Array<K>` | Collect to array |
| `==` | `(a &HashSet<K,H,E>, b &HashSet<K,H,E>) bool` | Set equality |
| `List` | `(sett &HashSet<K,H,E>) List<K>` | Convert to list |
| `GetRandomElement` | `(self &HashSet<K,H,E>, seed int) Opt<&K>` | Random element |

---

## `arrays` — Array Helpers

Helper functions for iterating over arrays. Provides `each` and `eachI` for
both static-sized and runtime-sized arrays, and iterator types for `foreach`.

### All-in-One Example

```vale
import * from stdlib.arrays

arr = [#1](10, 20, 30, 40, 50)

// Each — call function on each element
arr.each(&(x) => { println(x); })

// Each with index
arr.eachI(&(i, x) => {
  println(str(i) + ": " + str(x));
})

// Foreach over static array
foreach x in arr {
  println(x);
}

// Foreach with index
foreach [i, x] in arr.entries() {
  println(str(i) + ": " + str(x));
}
```

### Functions

| Function | Signature | Description |
|----------|-----------|-------------|
| `each` | `(arr &[#N]<V>T, func &F) void` | Call func on each SSA element |
| `eachI` | `(arr &[#N]<V>T, func &F) void` | Call func(index, element) on SSA |
| `each` | `(arr &[]T, func &F) void` | Call func on each RSA element |
| `eachI` | `(arr &[]T, func &F) void` | Call func(index, element) on RSA |

### Iterator Types

#### `StaticSizedArrayIter<N Int, V Variability, E>`

```vale
struct StaticSizedArrayIter<N Int, V Variability, E> where E Ref {
  arr &[#N]<V>E;
  pos! int;
}
```

Foreach support for static arrays:

```vale
func begin<N, V, E>(arr &[#N]<V>E) StaticSizedArrayIter<N, V, E>
func next<N, V, E>(iter &StaticSizedArrayIter<N, V, E>) Opt<&E>
```

#### `StaticSizedArrayEntriesIter<N Int, V Variability, E>`

```vale
struct StaticSizedArrayEntriesIter<N Int, V Variability, E> {
  arr &[#N]<V>E;
  pos! int;
}

func entries<N, V, E>(arr &[#N]<V>E) StaticSizedArrayEntriesIter<N, V, E>
```

#### `RuntimeSizedArrayIter<E>` and `RuntimeSizedArrayEntriesIter<E>`

```vale
struct RuntimeSizedArrayIter<E> where E Ref { ... }
struct RuntimeSizedArrayEntriesIter<E> where E Ref { ... }

func entries<E>(arr &[]E) RuntimeSizedArrayEntriesIter<E>
```

---

## `str` — String Slice and Operations

The `str` module provides the `StrSlice` type and string manipulation functions
including comparison, concatenation, search, and substring extraction.

### All-in-One Example

```vale
import * from stdlib.str

s = "hello world"

// Length
println(len(s));  // 11

// Slice
slice = s.slice(0, 5);
println(slice.str());   // "hello"

// Contains
println(s.contains("world"));  // true

// Find
pos = s.find("world");
println(pos.get());  // 6

// Concatenation
greeting = "hello" + " " + "world";

// Comparison
println("abc" == "abc");  // true
println("abc" <=> "def"); // negative

// Character operations
println(toAscii("A"));     // 65
println(fromAscii(65));    // "A"

// StrSlice
s2 = s.slice();
println(s2.str());
```

### Types

#### `StrSlice imm`

```vale
struct StrSlice imm {
  string str;
  begin int;
  end int;
}
```

An immutable view into a substring of a `str`. The fields refer to the backing
string and the start/end indices within it.

### Functions

| Function | Signature | Description |
|----------|-----------|-------------|
| `len` | `(s StrSlice) int` | Length of the slice |
| `slice` | `(s str) StrSlice` | Create slice from str |
| `slice` | `(s str, begin int) StrSlice` | Slice from begin to end |
| `slice` | `(s str, begin int, end int) StrSlice` | Sub-slice |
| `slice` | `(s StrSlice, begin int) StrSlice` | Relative sub-slice |
| `slice` | `(s StrSlice, begin int, end int) StrSlice` | Clamped relative sub-slice |
| `contains` | `(haystack str/StrSlice, needle str/StrSlice) bool` | Substring check |
| `find` | `(haystack str/StrSlice, needle str/StrSlice) Opt<int>` | Find first occurrence |
| `charAt` | `(s str/StrSlice, at int) str` | Single character |
| `str` | `(s StrSlice) str` | Convert slice to string |
| `==` | `(a str/StrSlice, b str/StrSlice) bool` | Equality |
| `!=` | `(a str/StrSlice, b str/StrSlice) bool` | Inequality |
| `<=>` | `(a str/StrSlice, b str/StrSlice) int` | Three-way comparison |
| `+` | `(a str/StrSlice, b str/StrSlice) str` | Concatenation |
| `toAscii` | `(s str/StrSlice) int` | First char to ASCII code |
| `fromAscii` | `(code int) str` | ASCII code to string |

---

## `stringutils` — String Utility Functions

Provides string operations: prefix/suffix checks, trimming, splitting,
parsing integers, replacing substrings, and `StringBuilder`.

### All-in-One Example

```vale
import * from stdlib.stringutils

// startsWith / endsWith
println(startsWith("hello world", "hello"));  // true
println(endsWith("hello world", "world"));    // true

// Trim
trimmed = trim("  \t\nhello  ");
println(trimmed.str());  // "hello"

// int parsing
parsed = int("42");
if not parsed.isEmpty() {
  println(parsed.get());  // 42
}

// Split
parts = split("a,b,c", ",");
println(parts.len());  // 3

// Replace
replaced = replaceAll("hello world", "world", "there");
println(replaced);  // "hello there"

// StringBuilder
sb = StringBuilder();
sb.print("The answer is ");
sb.print(42);
sb.println(".");
println(sb.str());

// Split once
result = splitOnce("a,b,c", ",");
if not result.isEmpty() {
  [before, after] = result.get();
  println(before.str());  // "a"
  println(after.str());   // "b,c"
}
```

### Hash/Equality Functors

```vale
struct StrHasher { }
func __call(self &StrHasher, original_str str) int

struct StrEquator { }
func __call(self &StrEquator, a str, b str) bool

struct StrSliceHasher { }
func __call(self &StrSliceHasher, s StrSlice) int

struct StrSliceEquator { }
func __call(self &StrSliceEquator, a StrSlice, b StrSlice) bool
```

### Types

#### `SplitResult`

```vale
struct SplitResult {
  beforeSplit StrSlice;
  afterSplit StrSlice;
}
```

#### `StringBuilder`

```vale
struct StringBuilder {
  parts List<StrSlice>;
}
```

```vale
sb = StringBuilder()
sb.print(s str/StrSlice/bool/int)    // append
sb.println(s str/StrSlice/int)       // append + newline
sb.str()                             // assemble string
sb.assembleStr()                     // assemble string
```

### Functions

| Function | Signature | Description |
|----------|-----------|-------------|
| `startsWith` | `(a str/StrSlice, b str/StrSlice) bool` | Prefix check |
| `endsWith` | `(a str/StrSlice, b str/StrSlice) bool` | Suffix check |
| `splice` | `(original str, at int, remove int, insert str) str` | Replace substring |
| `ltrim` | `(s str/StrSlice) StrSlice` | Strip leading whitespace |
| `rtrim` | `(s str/StrSlice) StrSlice` | Strip trailing whitespace |
| `trim` | `(s str/StrSlice) StrSlice` | Strip both sides |
| `isWhitespace` | `(s str/StrSlice) bool` | All whitespace? |
| `int` | `(s str/StrSlice) Opt<int>` | Parse integer |
| `splitOnce` | `(haystack, needle) Opt<SplitResult>` | First split |
| `split` | `(haystack, needle) List<StrSlice>` | All splits |
| `replaceAll` | `(source, needle, replacement) str` | Global replace |
| `clone` | `(s StrSlice) StrSlice` | Copy slice |

---

## `cast` — Type Concatenation Helpers

Provides conversion functions and string concatenation helpers for mixing
types with strings.

### All-in-One Example

```vale
import * from stdlib.cast

println(str(true));     // "true"
println(str(false));    // "false"
println(42 + " items"); // "42 items"
println("count: " + 5); // "count: 5"
println(3.14 + " rad"); // "3.14 rad"
println("pi is " + 3.14); // "pi is 3.14"
println("flag is " + true); // "flag is true"
```

### Functions

| Function | Signature | Description |
|----------|-----------|-------------|
| `void()` | `() void` | Unit value |
| `str(b bool) str` | `(bool) str` | Bool to string |
| `+` | `(int, str) str` | Int prefix concat |
| `+` | `(str, int) str` | Int suffix concat |
| `+` | `(str, i64) str` | i64 suffix concat |
| `+` | `(i64, str) str` | i64 prefix concat |
| `+` | `(str, bool) str` | Bool suffix concat |
| `+` | `(bool, str) str` | Bool prefix concat |
| `+` | `(float, str) str` | Float suffix concat |
| `+` | `(str, float) str` | Float prefix concat |

---

## `print` — Output Functions

Basic console output.

### All-in-One Example

```vale
import * from stdlib.print

print("hello");     // prints without newline
println("world");   // prints with newline
println(42);        // prints "42\n"
println(true);      // prints "true\n"
```

### Functions

| Function | Signature | Description |
|----------|-----------|-------------|
| `print` | `(s str) void` | Print string |
| `print` | `(i int) void` | Print int |
| `print` | `(b bool) void` | Print bool |
| `println` | `(s str) void` | Print string + newline |
| `println` | `(i int) void` | Print int + newline |
| `println` | `(b bool) void` | Print bool + newline |

---

## `panic` — Assertions and Abort

Provides assertions and panic (abort) for unrecoverable errors.

### All-in-One Example

```vale
import * from stdlib.panic

vassert(true);               // passes
vassert(1 == 1, "math works");

x = 42;
y = 42;
vassertEq(&x, &y);            // checks ==

// Abort:
// panic("fatal error");
// __pretend<int>()  — unsafe type assertion
```

### Functions

| Function | Signature | Description |
|----------|-----------|-------------|
| `__pretend<T>` | `() T` | Unsafe type coercion (never runs) |
| `vassert` | `(cond bool) void` | Assert condition |
| `vassert` | `(cond bool, msg str) void` | Assert with message |
| `vassertEq` | `(a &T, b &T) void` | Assert equality |
| `vassertEq` | `(a &T, b &T, msg str) void` | Assert equality with message |

---

## `logic` — Boolean Operations

Boolean operations.

### Functions

```vale
not(b bool) bool              // logical NOT
==(left bool, right bool) bool  // boolean equality
!=(a &T, b &T) bool             // inequality (requires ==)
```

---

## `math` — Mathematical Utilities

Provides common mathematical functions, integer range iteration helpers,
hasher/equator functors, and FFI math bindings.

### All-in-One Example

```vale
import * from stdlib.math

// Math functions
println(min(10, 20));    // 10
println(max(10, 20));    // 20
println(clamp(5, 0, 10)); // 5
println(abs(-7));        // 7
println(signum(-3));     // -1

// Range iteration
foreach i in range(0, 10) {
  println(i);
}

// Hasher/Equator functors
hasher = IntHasher();
hash = hasher(42);

equator = IntEquator();
println(equator(1, 1));  // true

// FFI math
// fsqrt(9.0)  — float sqrt
// lshift, rshift, xor on i64
// i64(x int)  — int to i64 conversion
```

### Functions

| Function | Signature | Description |
|----------|-----------|-------------|
| `min` | `(a int, b int) int` | Minimum |
| `max` | `(a int, b int) int` | Maximum |
| `clamp` | `(x int, minimum int, maximum int) int` | Clamp to range |
| `abs` | `(a int) int` | Absolute value |
| `abs` | `(a i64) i64` | Absolute value (i64) |
| `signum` | `(a int) int` | Sign (-1, 0, 1) |
| `range` | `(begin int, end int) IntRange` | Iterable range |
| `fsqrt` | `(x float) float` | Float square root (extern) |
| `lshift` | `(x i64, by int) i64` | Left shift (extern) |
| `rshift` | `(x i64, by int) i64` | Right shift (extern) |
| `xor` | `(a i64, b i64) i64` | Bitwise XOR (extern) |
| `i64` | `(x int) i64` | Int to i64 (extern) |

### Types

#### `IntRange` and `IntRangeIter`

```vale
struct IntRange { begin int; end int; }
struct IntRangeIter { range &IntRange; i! int; }
```

Support `foreach i in range(0, 10)`.

#### `IntHasher` and `IntEquator`

```vale
struct IntHasher { }
func __call(this &IntHasher, x int) int

struct IntEquator { }
func __call(this &IntEquator, a int, b int) bool { a == b }
```

For use with `HashMap` and `HashSet`.

---

## `optutils` — Optional Helpers

Utility functions extending the built-in `Opt<T>` type.

### All-in-One Example

```vale
import * from stdlib.optutils

x Opt<int> = Some(42)

// Check non-empty
println(x.nonEmpty())  // true

// Get with custom message
value = x.get("custom message")
println(value)  // 42

// Map over option
doubled = x.map(&(v) => v * 2)
println(doubled.get())  // 84

// Provide default if None
none Opt<int> = None<int>()
result = none.or({ 99 })
println(result)  // 99

// Equality
println(Some(1) == Some(1))  // true

// Clone
clone = x.clone()
```

### Functions

| Function | Signature | Description |
|----------|-----------|-------------|
| `nonEmpty` | `(self &Opt<T>) bool` | Inverse of isEmpty |
| `get` | `(opt Opt<T>, msg str) T` | Unwrap with message |
| `get` | `(opt &Opt<T>, msg str) &T` | Unwrap ref with message |
| `clone` | `(self &Opt<T>) Opt<T>` | Deep copy |
| `map` | `(self &Opt<T>, func &F) Opt<R>` | Transform value |
| `or` | `(self Opt<T>, func &F) T` | Default via callable |
| `or` | `(self &Opt<T>, func &F) &T` | Default ref via callable |
| `==` | `(a &Opt<T>, b &Opt<T>) bool` | Optional equality |

---

## `resultutils` — Result Helpers

Utility functions for `Result<Ok, Err>`.

### Functions

```vale
// Get Ok value or fallback reference
get_or(result &Result<OkType, ErrType>, default &OkType) &OkType

// Get Ok value or compute from Err via callable
get_or<F>(result Result<OkType, ErrType>, func &F) OkType
where func(&F, ErrType)OkType
```

### Example

```vale
import * from stdlib.resultutils

result = Ok<int, str>(42)

// Default ref
value = get_or(&result, &0)
println(value)  // 42

// Transform error
errResult = Err<int, str>("fail")
recovered = get_or(errResult, &(e) => {
  println("error was: " + e)
  0
})
println(recovered)  // 0
```

---

## `error` — Error Interface

Minimal interface for error types used with the `path` module.

```vale
import * from stdlib.error

struct Call {
  name str;
}

interface Error {
  func description(virtual self &Error) str;
  func trace(virtual self &Error) List<Call>;
}
```

---

## `command` — Subprocess Spawning

Spawns and manages OS subprocesses. Programs are resolved via `PATH`.

### All-in-One Example

```vale
import * from stdlib.command

// Spawn a command
sp = Subprocess("echo", &["hello", "world"])
if sp.is_ok() {
  subprocess = sp.expect("ok")

  // Capture all output
  result = subprocess.capture_and_join()
  println(result.return_code)  // 0
  println(result.stdout)        // "hello world\n"
} else {
  println("failed: " + (sp).expect_err(""))
}

// Streaming output
sp2 = Subprocess("make", &["-j4"])
if sp2.is_ok() {
  code = (sp2).get().print_and_join()
}
```

### Types

#### `Subprocess`

```vale
struct Subprocess {
  command str;
  maybe_cwd Opt<str>;
  handle i64;
}
```

#### `ExecResult`

```vale
struct ExecResult {
  return_code int;
  stdout str;
  stderr str;
}
```

### Functions

| Function | Signature | Description |
|----------|-----------|-------------|
| `print_and_join` | `(self Subprocess) int` | Stream output to terminal, wait |
| `capture_and_join` | `(self Subprocess) ExecResult` | Capture all output, wait |
| `join` | `(self Subprocess) int` | Wait for exit, return code |
| `alive` | `(self &Subprocess) bool` | Still running? |
| `read_stdout` | `(self &Subprocess, len int) str` | Read stdout |
| `read_stderr` | `(self &Subprocess, len int) str` | Read stderr |
| `read_all_stdout` | `(self &Subprocess) str` | Drain stdout |
| `consume_and_join` | `(self, stdout_consumer, stderr_consumer) int` | Stream via callbacks |
| `expect_or` | `(result &ExecResult, func &F) str` | Check result or callback |

---

## `path` — Filesystem Path Manipulation

Cross-platform filesystem path manipulation and I/O.

### All-in-One Example

```vale
import * from stdlib.path

base = Path("./data")
base.CreateDirAll(true).expect("create")

// Path joining with /
file = base / "hello.txt"
file.writeString("Hello, world!\n")

content = file.readAsString()
println(content)

// Inspection
println(file.str())                      // "./data/hello.txt"
println(file.name())                     // "hello.txt"
println(file.is_file())                  // true
println(base.is_dir())                   // true

// Listing
files = base.iterdir()
foreach f in files {
  println(f.str())
}

// Temp dir
tmp = GetTempDir()
println(tmp.str())

// Cleanup
base.RemoveDirAll().expect("remove")
```

### Types

```vale
export Array<str> as StrArray
export Array<str> as MutStrArray
export List<Path> as PathList

interface FileError { }
struct FileNotFoundError { path Path; }
impl FileError for FileNotFoundError;

exported struct Path {
  segments List<str>;
}
```

### Constructors

```vale
Path(s str) Path   // parse path, split on / and \
```

### Functions

| Function | Signature | Description |
|----------|-----------|-------------|
| `str` | `(path &Path) str` | Join segments with separator |
| `name` | `(path &Path) str` | Final segment |
| `parent` | `(path &Path) Path` | Parent path |
| `directory` | `(path &Path) Path` | Containing directory |
| `resolve` | `(self &Path) Path` | Canonical absolute |
| `exists` | `(path &Path) bool` | File/dir exists? |
| `is_dir` | `(path &Path) bool` | Is directory? |
| `is_file` | `(path &Path) bool` | Is file? |
| `/` | `(path &Path, segment str) Path` | Path join |
| `clone` | `(self &Path) Path` | Deep copy |
| `readAsString` | `(path &Path) str` | Read file |
| `writeString` | `(path &Path, contents str) void` | Write file |
| `iterdir` | `(path &Path) List<Path>` | List directory |
| `CreateDir` | `(path &Path, allow_existing bool) Result<void, FileError>` | Create single dir |
| `CreateDirAll` | `(path &Path, allow_existing bool) Result<void, FileError>` | Create dir tree |
| `RemoveDir` | `(path &Path) Result<void, FileError>` | Remove empty dir |
| `RemoveDirAll` | `(path &Path) Result<void, FileError>` | Remove dir tree |
| `RemoveFile` | `(path &Path) Result<void, FileError>` | Remove file |
| `Rename` | `(path &Path, dest &Path) Result<void, FileError>` | Move/rename |
| `ListDir` | `(path &Path) Result<List<Path>, FileError>` | Fallible list dir |
| `IsSymLink` | `(path &Path) Result<bool, FileError>` | Is symlink? |
| `IsDirectory` | `(path &Path) Result<bool, FileError>` | Is directory? |
| `GetTempDir` | `() Path` | System temp dir |
| `==` | `(a &Path, b &Path) bool` | Segment equality |

---

## `flagger` — Command-Line Flag Parsing

A command-line flag parsing library. Provides types to define flags and
subcommands, a parser to process command-line arguments, and accessor
functions to retrieve flag values.

### All-in-One Example

```vale
import * from stdlib.flagger
import * from stdlib.collections.list

flag_list = [#](
  Flag("--verbose", FLAG_NOTHING(),
       "Enable verbose output.", "--verbose",
       "Print detailed information."),
  Flag("--output", FLAG_STR(),
       "Output file path.", "--output=out.txt",
       "Path to the output file."),
  Flag("--count", FLAG_INT(),
       "Number of iterations.", "--count=10",
       "How many times to repeat."),
)

args = ["prog", "--verbose", "--output=log.txt", "--count=5"]
parsed = parse_all_flags(flag_list, args)

// Nothing flag
if get_nothing_flag(parsed, "--verbose") {
  println("Verbose mode on")
}

// String flag
output = get_string_flag(parsed, "--output")
if not output.isEmpty() {
  println("Output: " + output.get())
}

// Int flag with default
count = get_int_flag(parsed, "--count", 1)
println("Count: " + str(count))

// Required flag (panics if missing):
// name = expect_string_flag(parsed, flag_list, "--name")
```

### Flag Type Constants

| Function | Value | Meaning |
|----------|-------|---------|
| `FLAG_NOTHING()` | 0 | Standalone flag (e.g. `--verbose`) |
| `FLAG_INT()` | 1 | Integer value (e.g. `--count=5`) |
| `FLAG_STR()` | 2 | String value (e.g. `--output=file`) |
| `FLAG_TOKN()` | 3 | Opaque token string |
| `FLAG_BOOL()` | 4 | Boolean value (`true`/`false`) |
| `FLAG_LIST_INT()` | 5 | List of ints |
| `FLAG_LIST_STR()` | 6 | List of strings |
| `FLAG_LIST_TOKN()` | 7 | List of tokens |
| `FLAG_LIST_BOOL()` | 8 | List of booleans |
| `FLAG_LIST_ANY()` | 9 | List of FlagType |

### Types

#### `Flag`

```vale
struct Flag {
  name str;
  type int;
  short_desc str;
  example str;
  desc str;
}
```

#### `ParsedFlag`

```vale
struct ParsedFlag {
  name str;
  val FlagType;
}
```

#### `ParsedFlagList`

```vale
struct ParsedFlagList {
  parsed_flags List<ParsedFlag>;
  unrecognized_inputs List<str>;
}
```

#### `CommandList<N Int>` and `Command`

```vale
struct CommandList<N Int> { commands [#N]Command; }
struct Command { name str; desc str; short_desc str; example str; }
```

#### `FlagType` (interface)

```vale
interface FlagType { }
struct FlagInt    { value int;  }
struct FlagString { value str;  }
struct FlagToken  { value str;  }
struct FlagBool   { value bool; }
struct FlagAnyList { value List<FlagType>; }
```

### Functions

| Function | Signature | Description |
|----------|-----------|-------------|
| `verify` | `(command_list &CommandList<N>, command_str str) bool` | Valid subcommand? |
| `parse_all_flags` | `(flag_list &[#N]<V>Flag, args []str) ParsedFlagList` | Parse all args |
| `parse_flag` | `(args []str, flag_type int, i int) (ParsedFlag, int)` | Parse single flag |
| `explain_flag` | `(flag_list &[#N]Flag, flag_name str) void` | Print flag help |
| `get_nothing_flag` | `(parsed &ParsedFlagList, flag_name str) bool` | Flag present? |
| `get_string_flag` | `(parsed &ParsedFlagList, flag_name str) Opt<str>` | Get string value |
| `get_string_flag` | `(parsed &ParsedFlagList, flag_name str, default str) str` | With default |
| `expect_string_flag` | `(parsed &ParsedFlagList, flag_list, flag_name str) str` | Required string |
| `get_bool_flag` | `(parsed, flag_name) Opt<bool>` | Get bool value |
| `get_bool_flag` | `(parsed, flag_name, default bool) bool` | With default |
| `expect_bool_flag` | `(parsed, flag_list, flag_name) bool` | Required bool |
| `get_int_flag` | `(parsed, flag_name) Opt<int>` | Get int value |
| `get_int_flag` | `(parsed, flag_name, default int) int` | With default |
| `expect_int_flag` | `(parsed, flag_list, flag_name) int` | Required int |

---

## `ifunction1` — Single-Parameter Function Interface

```vale
interface IFunction1<M Mutability, P1 Ref, R Ref> M {
  func __call(virtual self &IFunction1<M, P1, R>, p1 P1) R;
}
```

A generic interface for single-parameter callables parameterized by mutability
(`M`), parameter type (`P1`), and return type (`R`).

---

## `date` — Unix Timestamp

```vale
extern func UnixTimestamp() i64;
```

Returns the current Unix timestamp in microseconds as an `i64`.

```vale
ts = UnixTimestamp();
println(ts);
```

---

## `mtpid` — Micro Time Process ID

MTPID (Micro Time Process ID) is a unique identifier combining the process ID
and microsecond timestamp into an `i64`.

```vale
id = MtpId();
println(id);
```

---

## `os` — Operating System Queries

```vale
extern func IsWindows() bool;
```

```vale
if IsWindows() {
  println("Running on Windows");
} else {
  println("Not Windows");
}
```

---

## `stdin` — Standard Input

```vale
extern func stdinReadInt() int;
extern func getch() int;
```

```vale
// Read an integer from stdin
val = stdinReadInt();

// Read a single character (blocking)
ch = getch();
```

---

## `testsuite` — Unit Test Framework

Simple unit test framework.

### All-in-One Example

```vale
import * from stdlib.testsuite
import * from stdlib.panic

suite = TestSuite()
suite.test("addition", {
  vassert(1 + 1 == 2)
})
suite.test("string", {
  vassert("hello" + " " + "world" == "hello world",
          "string concatenation works")
})
suite.finish()
// Output: Passed all 2 tests!
```

### Types

#### `TestSuite`

```vale
struct TestSuite {
  filter str;
  num_tests_ran! int;
  num_tests_skipped! int;
}
```

#### `SubTestSuite`

```vale
struct SubTestSuite {
  suite &TestSuite;
  prefix str;
}
```

### Functions

| Function | Signature | Description |
|----------|-----------|-------------|
| `TestSuite` | `() TestSuite` | Create suite |
| `finish` | `(suite TestSuite) void` | Print results |
| `test` | `(suite &TestSuite, name str, lambda &F) void` | Register test |
| `should_equal` | `(a &T, b &T) void` | Assert equal |
| `should_not_equal` | `(a &T, b &T) void` | Assert not equal |
| `sub` | `(suite &TestSuite, prefix str, body &F) void` | Create sub-suite |
| `SubTestSuite` | `(suite &TestSuite, prefix str) SubTestSuite` | Create sub-suite |