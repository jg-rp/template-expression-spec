# A Unified Expression Grammar for Liquid Templates

## Abstract

This document specifies a unified, implementation‑independent expression language for Liquid templates. It describes the concrete grammar, the runtime value domain, conversion functions, operator semantics, and extension points (Drops). The goal is a deterministic, total evaluation model where every well‑formed expression yields a `RuntimeValue` and runtime evaluation never throws.

## Status

Draft — specification in progress. Feedback and test cases are welcome.

## History

TODO:

## Overview

TODO:

### Total Evaluation

Evaluation never fails. Evaluating any expression always produces a value. Every operator, filter, and conversion must produce a value for every possible input.

Formally, expressions are a closed algebra over `RuntimeValue`. For every expression `e` and environment `ρ`:

```
⟦ e ⟧(ρ) ∈ RuntimeValue
```

Every syntactically valid expression evaluates to a value and does not raise an error at render time.

## Data Types and Values

All expressions evaluate to a defined type. `DataValue` defines all possible kinds of value that can exist inside the template data model.

```
DataValue =
    Null
  | Boolean
  | Number
  | String
  | Array<DataValue>
  | Object<String → DataValue>
```

`RuntimeValue` describes the result of evaluating an expression. Note that `DataValue` is the subset of `RuntimeValue` that does not contain `Drop` or `Nothing`.

```
RuntimeValue =
    DataValue
  | Array<RuntimeValue>
  | Object<String → RuntimeValue>
  | Drop
  | Nothing
```

`Nothing` represents the absence of a value produced during evaluation and is distinct from `Null` (or implementation-specific `nil`, `None`, `undefined` etc.).

### Extension Types (Drops)

Implementations may expose developer-defined objects known as Drops. A Drop is an object that can be coerced into a data value when required, with the help of a context hint.

```
ToLiquid : Drop × ContextHint → RuntimeValue
```

Where:

```
ContextHint ∈ { default, numeric, string, boolean, iterable, render, array }
```

Constraints:

- `ToLiquid(drop, boolean)` MUST return `Boolean` or `Nothing`.
- `ToLiquid(drop, default)` MUST return `DataValue`.
- `ToLiquid(drop, iterable)` MUST return `Array<RuntimeValue>`, a `Drop` that MUST implement the sequence protocol, or `Nothing`
- `ToLiquid(drop, numeric)` MUST return `Number` or `Nothing`.
- `ToLiquid(drop, string)` MUST return `String` or `Nothing`.
- `ToLiquid(drop, render)` MUST return `String` or `Nothing`.
- `ToLiquid(drop, array)` MUST return `Array<RuntimeValue>` or `Nothing`.

The result of `ToLiquid(drop, default)` MUST be a valid `DataValue` as defined above, meaning it MUST NOT contain `Drop` at any depth.

The following table shows when each hint applies.

| Context                          | Hint     |
| -------------------------------- | -------- |
| Arithmetic                       | numeric  |
| String concatenation             | string   |
| Boolean test (`if`, `and`, `or`) | boolean  |
| Comparison                       | default  |
| Rendering `{{ x }}`              | render   |
| `for` iterable expression        | iterable |
| Filter arguments (general)       | default  |
| Used by `ToArray`                | array    |

#### Sequence protocol

A Drop MAY implement the `Sequence` protocol to facilitate lazy iteration with the `for` tag or sequence aware filters.

A Drop implements the `Sequence` protocol if it supports:

```
length() → Number
slice(offset, limit, reversed) → Drop
iterate() → Iterator<RuntimeValue>
```

Constraints:

- `length()` MUST reflect the current logical sequence.
- `slice()` MUST return a `Drop` implementing the `Sequence` protocol.
- `iterate()` MUST yield exactly `length()` elements.

#### Equality Protocol

A Drop MAY implement the `Equality` protocol for interaction with `==` and `!=` operators, without first coercing to a data value.

```
Equals : Drop × RuntimeValue → Boolean | Nothing
```

A Drop implements the `Equality` protocol if it supports:

```
Equals(x) -> Boolean | Nothing
```

`equals` MUST NOT throw an error.

#### Ordering Protocol

A Drop MAY implement the `Ordering` protocol for interaction with `<`, `>`, `<=`, and `>=` operators, without first coercing to a data value.

```
LessThan : Drop × RuntimeValue → Boolean | Nothing
```

A Drop implements the `Ordering` protocol if it supports:

```
LessThan(x) -> Boolean | Nothing
```

#### Membership Protocol

A Drop MAY implement the `Membership` protocol for interaction with `in` and `contains` operators, without first coercing to a data value.

```
Contains : Drop × RuntimeValue → Boolean | Nothing
```

A Drop implements the `Membership` protocol if it supports:

```
Contains(x) -> Boolean | Nothing
```

## Type Conversion

Liquid performs automatic type conversions in some contexts. Here we define abstract conversion functions for runtime values, each of which is deterministic and never throws an error.

```
ToBoolean  : RuntimeValue → Boolean
ToNumber   : RuntimeValue → Number | Nothing
ToString   : RuntimeValue → String
ToArray    : RuntimeValue → Array<RuntimeValue>
```

Implicit conversions occur in the following contexts (each uses the corresponding abstract conversion function):

- Arithmetic and numeric operators: `ToNumber`
- Unary `+`/`-`: `ToNumber`
- String concatenation (filters or template rendering): `ToString`
- Boolean conditions used by `if`, ternary `if` expressions, `and`, `or`, and
  `not`: `ToBoolean`
- Comparisons that require primitive values: `ToLiquid(…, default)` then structural comparison; numeric comparisons use `ToNumber` when both sides are numeric or coercible to numeric.
- `for` iterable expressions: `ToArray` / `ToLiquid(…, iterable)`
- Filter arguments (general): `ToLiquid(…, default)` unless a filter documents a different required hint
- `ToArray` helper and sequence normalization: `ToArray`

Conversions are deterministic and must never raise errors; when a conversion cannot produce the requested target it returns `Nothing` where specified.

### ToBoolean(x)

The abstract operation `ToBoolean` is defined to be identical to `IsTruthy`.

```
ToBoolean : RuntimeValue → Boolean
```

An evaluation result is truthy if it represents a non-empty, non-zero, non-null value.

| Input Type | Result                                 |
| ---------- | -------------------------------------- |
| Nothing    | false                                  |
| Null       | false                                  |
| Boolean    | identity                               |
| Integer    | x ≠ 0                                  |
| Float      | x ≠ 0.0                                |
| String     | length(x) > 0                          |
| Array      | length(x) > 0                          |
| Object     | size(o) > 0                            |
| Drop       | ToLiquid(x, boolean); false if Nothing |

### ToNumber(x)

Returns either Integer or Decimal.

```
ToNumber  : RuntimeValue → Number | Nothing
```

| Input Type | Result                                      |
| ---------- | ------------------------------------------- |
| Integer    | identity                                    |
| Float      | identity                                    |
| Boolean    | true → 1, false → 0                         |
| Nothing    | Nothing                                     |
| Null       | Nothing                                     |
| String     | parse numeric literal; if invalid → Nothing |
| Array      | Nothing                                     |
| Object     | Nothing                                     |
| Drop       | ToLiquid(x, numeric)                        |

### ToString(x)

```
ToString : RuntimeValue → String
```

| Input Type | Result                               |
| ---------- | ------------------------------------ |
| String     | identity                             |
| Integer    | decimal representation               |
| Float      | canonical decimal                    |
| Boolean    | `"true"` or `"false"`                |
| Null       | `""`                                 |
| Nothing    | `""`                                 |
| Array      | JSON-formatted array                 |
| Object     | JSON-formatted object                |
| Drop       | ToLiquid(x, string); `""` if Nothing |

### ToArray(x)

```
ToArray : RuntimeValue → Array<RuntimeValue>
```

| Input Type      | Result                              |
| --------------- | ----------------------------------- |
| Array           | identity                            |
| Null            | []                                  |
| Nothing         | []                                  |
| Drop            | ToLiquid(x, array) or [] if Nothing |
| Any other value | [x]                                 |

## Truthiness

The language adopts structural truthiness. Empty strings, empty arrays, empty objects, zero numbers, null, and absence (`Nothing`) are falsy. All other values are truthy. This rule is uniform across value types and does not depend on host-language semantics.

Condition semantics

Conditions are evaluated by first evaluating the condition expression and then applying `ToBoolean` to the result. For ternary expressions of the form `consequence if condition else alternative` the `condition` is evaluated first; depending on its truthiness only the selected branch (`consequence` or `alternative`) is subsequently evaluated. Implementations MUST not evaluate the unselected branch.

The `if` tag and boolean operators treat their operand values via `ToBoolean`. Drops used in boolean contexts are coerced using `ToLiquid(drop, boolean)`, with `Nothing` treated as `false`.

## Operators

### Comparison Operators

Comparison operators are total and always produce a Boolean value. If operands are not comparable under the operator, the result is false.

```
==, !=, <, >, <=, >= : RuntimeValue × RuntimeValue → Boolean
```

We first define `==` and `<`, then `!=`, `>`, `<=` and `>=` in terms of `==` and `<`.

- A comparison using the operator `==` evaluates to true if the comparison is between:
  - `Nothing` and `Nothing`.
  - numbers, where the numbers compare equal using an implementation-specific equality.
  - equal primitive data values
  - arrays of the same length where each element of the first array is equal to the corresponding element in the second array.
  - objects with the same collection of names and, for each of those names, the associated values are equal.
  - drops:
    1. If `a` is Drop and implements `Equals` and `a.Equals(b)` is true.
    2. Else if `b` is Drop and implements `Equals` and `b.Equals(a)` is true.
    3. Else:
       - Coerce both via `ToLiquid(…, default)`
       - Compare `DataValue` structurally

- A comparison using the operator `<` yields true if the comparison is between values that are both numbers or both strings and that satisfy the comparison:
  - For numbers: numeric ordering is used. Integers and floating values are compared by their numeric value; implementations may use a single representation (e.g. IEEE 754 BigDecimal) but comparisons must behave as the mathematical numeric ordering (smaller → less-than).
  - For strings: by default strings are ordered by Unicode scalar (code point) order. Implementations MAY provide an option to use the Unicode Collation Algorithm (UCA) for locale sensitive ordering, but the canonical spec semantics are Unicode code point ordering to ensure deterministic results.
- Or, if either operand is a drop:
  1. If `a` is `Drop` and implements `LessThan` and `a.LessThan(b)` is true.
  2. Else if `b` is `Drop` and implements `LessThan` and `b.LessThan(a)` is true.
  3. Else:
     - Coerce both via `ToLiquid(…, default)`
     - Attempt standard ordering

`!=`, `>`, `<=` and `>=` are defined in terms of `==` and `<`.

```
x != y  = not (x == y)
x > y   = y < x
x <= y  = (x < y) or (x == y)
x >= y  = (y < x) or (x == y)
```

### Membership Operators

Membership tests (`contains` and `in`) determine whether a value appears in a
container. Semantics are:

1. If `container` is a `Drop` and implements `Contains`, call
   `container.Contains(element)`. If it returns `Boolean`, use that value; if
   it returns `Nothing`, treat as `false`.
2. Else if `container` is an `Array` or a `Sequence`: iterate its elements and
   compare each element to `element` using `==`. If any element compares equal
   then the result is `true`, otherwise `false`.
3. Else if `container` is an `Object`: membership tests whether there exists a
   key equal to the `element` when the `element` is converted to `String` (or
   compared structurally to the keys as implementation prefers). Typical
   implementations coerce `element` to `String` and test key presence.
4. Else if `container` is a `String` and `element` is a `String`: `contains`
   tests substring inclusion; `in` with swapped operands follows the same
   rule.
5. Otherwise, coerce `container` via `ToLiquid(…, default)` and retry from
   the top. If no rule applies, return `false`.

`in` is defined as `element in container` (i.e. RHS is the container). Both
`contains` and `in` produce a `Boolean` result.

### Logical Operators

`and` and `or` are short‑circuiting operators and return the last evaluated
operand (not necessarily a Boolean). Their semantics:

- `x and y`: evaluate `x`; if `ToBoolean(x)` is falsy return `x`; otherwise
  evaluate and return `y`.
- `x or y`: evaluate `x`; if `ToBoolean(x)` is truthy return `x`; otherwise
  evaluate and return `y`.
- `not x`: evaluate `x` then return `not ToBoolean(x)` (a Boolean).

These rules preserve short‑circuit evaluation and allow logical expressions to be used as value selectors. When used in a boolean context (e.g. `if`), the resulting value is coerced with `ToBoolean`.

### Arithmetic Operators

Arithmetic operators are defined in terms of numeric conversion and can produce `Nothing`. Each operand is converted to a `Number` via the abstract function `ToNumber`.

```
+, -, *, /, % : EvalValue × EvalValue → Number | Nothing
+ , - (unary) : EvalValue → Number | Nothing
```

For any infix arithmetic operator `⊗ ∈ { +, −, *, /, % }`:

```
x ⊗ y = ToNumber(x) ⊗ₙ ToNumber(y)
```

1. If either operand is `Nothing` after `ToNumber(operand)`, the result is `Nothing`.
2. Otherwise apply numeric operator, or `Nothing` if divide by zero.

For unary prefix operators:

```
+x = ToNumber(x)
-x = - ToNumber(x)
```

1. If the operand is `Nothing` after `ToNumber(operand)`, the result is `Nothing`.
2. Otherwise apply numeric prefix operator.

Arithmetic operators MUST share semantics with their filter equivalents - `plus`, `minus`, `times`, etc.

## Filters

Filters are syntactic sugar for function application. An expression with filters:

```
expr | filter1: a, b | filter2: c
```

desugars to nested function calls where the previous expression is passed as the first argument to the next filter:

```
filter2(filter1(expr, a, b), c)
```

When a filter is invoked any positional and keyword arguments are evaluated left-to-right before the filter is called. If an argument is a lambda, it is passed as a callable object rather than evaluated immediately. Filters receive their arguments already coerced according to their documented parameter expectations (implementations may coerce using `ToLiquid(…, default)` if the filter does not specify otherwise).

## Variables and Paths

Variable resolution proceeds as follows:

- A bare `name` is looked up in the current environment (local/context variables). If present, that value is returned.
- If the path contains segments (e.g. `a.b[c].d`), evaluate each selector in sequence. For a dotted segment `.name` perform a lookup as an object key or a property access on the current value; for a bracketed selector `[expr]` evaluate `expr` and use the resulting value as the key or index (strings and numbers are commonly used as keys/indices).
- If an intermediate segment yields `Nothing`, subsequent segments evaluate to `Nothing` and the whole path yields `Nothing`.
- Accessing a missing key on an object yields `Nothing` (not an error).
- Numeric indices on arrays use `ToNumber` for the selector, and out‑of‑range accesses yield `Nothing`.

Implementations SHOULD treat property access on host objects according to a well‑documented resolution order (e.g. keys first, then methods) and MUST avoid raising exceptions during lookup — missing or inaccessible values map to `Nothing`.

### Predicates

A predicate is an optional trailing path segment of the form `.predicate?`. Predicates are syntactically distinct from shorthand name segments in that they must end in a question mark `?` and they must be the last segment of a path.

Note that `?` is not a valid character for a shorthand name segment. Should a template author need to reference a value by a key containing `?`, they must use bracketed syntax `some["thing?"]`.

All predicates are total over `RuntimeValue` and MUST return `Boolean`.

```
Predicate : RuntimeValue → Boolean
```

For any predicate `.p?` and accompanying abstract function `IsP`:

```
x.p?
```

Is semantically equivalent to:

```
IsP(x)
```

#### IsBlank(x)

`IsBlank` returns true for null-like empty textual or collection values.
Note that `Nothing` is distinct from `Null` and is not considered blank.

```
IsBlank(x) =
  x is Null
 OR x is String and trim(x) = ""
 OR x is Array and length(x) = 0
 OR x is Object and size(x) = 0
 OTHERWISE false

blank?(Nothing) = false
empty?(Nothing) = false
```

The absence of a value (`Nothing`) is not considered blank.

```
IsBlank(x) =
    x is Null
 OR x is String and trim(x) = ""
 OR x is Array and length(x) = 0
 OTHERWISE false

blank?(Nothing) = false
empty?(Nothing) = false
```

#### IsEmpty(x)

`IsEmpty` is true for values that are empty collections or empty strings. As
with `IsBlank`, `Nothing` is not considered empty.

```
IsEmpty(x) =
  x is String and length(x) = 0
 OR x is Array and length(x) = 0
 OR x is Object and size(x) = 0
 OTHERWISE false
```

The absence of a value (`Nothing`) is not considered empty.

```
IsEmpty(x) =
    x is String and length(x) = 0
 OR x is Array and length(x) = 0
 OR x is Object and size(x) = 0
 OTHERWISE false
```

#### IsDefined(x)

`IsDefined` distinguishes present values from the absence `Nothing`.

```
IsDefined(Nothing) → false
Otherwise → true
```

```
IsDefined(Nothing) → false
Otherwise → true
```

#### IsString(x)

```
IsString(x) =
  x is String → true
  otherwise   → false
```

```
IsString(x) =
    x is String → true
    otherwise   → false
```

#### IsNull(x)

```
IsNull(x) =
  x is Null → true
  otherwise → false
```

```
IsNull(x) =
    x is Null → true
    otherwise → false
```

#### IsNumber(x)

```
IsNumber(x) =
  x is Number → true
  otherwise   → false
```

```
IsNumber(x) =
    x is Number → true
    otherwise   → false
```

#### IsBoolean(x)

```
IsBoolean(x) =
  x is Boolean → true
  otherwise    → false
```

```
IsBoolean(x) =
    x is Boolean → true
    otherwise    → false
```

#### IsArray(x)

```
IsArray(x) =
  x is Array → true
  otherwise  → false
```

```
IsArray(x) =
    x is Array → true
    otherwise  → false
```

#### IsObject(x)

```
IsObject(x) =
  x is Object → true
  otherwise   → false
```

```
IsObject(x) =
    x is Object → true
    otherwise   → false
```
