# A Unified Expression Grammar for Liquid Templates

## Abstract

This document defines a unified, implementation‑independent expression language for Liquid-style templates.

This specification focuses strictly on the internal mechanics of expressions. Notably, this document does not define the surrounding tag architecture (such as the specific implementation of `{% if %}` or `{% for %}`) nor does it provide a "standard library" of filters.

Compatibility with existing Liquid implementations is explicitly not a goal.

## Status

Draft - specification in progress. Feedback and test cases are welcome.

## Introduction

TODO:

### Terminology

- _Expression_: An expression is the fundamental unit of computation within a Liquid template, representing a sequence of identifiers, literals, and operators that resolves to a value. Expressions serve as the logic centers inside Liquid tags: they appear within output delimiters to render data directly to the page (e.g., `{{ user.name | upcase }}`), inside conditional tags to govern template logic (e.g., `{% if item.price > 100 %}`), and as the data sources for iterations (e.g., `{% for product in collections.frontpage %}`)

  For each of the preceding examples, this tables isolates the expression part of the markup to illustrate some of the places an expression can appear.

  | Markup                                       | Expression              |
  | -------------------------------------------- | ----------------------- |
  | `{{ user.name \| upcase }}`                  | `user.name \| upcase`   |
  | `{% if item.price > 100 %}`                  | `item.price > 100`      |
  | `{% for product in collections.frontpage %}` | `collections.frontpage` |

- _Filter_: TODO:

### History

This document is based on Shopify's [Liquid](https://github.com/Shopify/liquid) project and other implementations derived from Shopify's reference implementation.

Historically, Liquid expressions have varied subtly depending on context - certain tags treated operators or filters differently, and precedence rules were not globally consistent.

This document aims to replace ad hoc behavior with a single, context-independent grammar and a clear evaluation model.

### Overview of Liquid Expressions

The Unified Expression Grammar is designed for consistency and reliability, where every syntactically valid expression is guaranteed to produce a result rather than an error.

Every operator, filter, and path resolution is a total function that maps inputs to a defined runtime value. If a conversion or lookup cannot proceed normally, it yields `Nothing` - a distinct internal state representing the absence of a value, which is then handled deterministically by subsequent operations.

Formally, for every expression $e$ and environment $\rho$:

$$⟦ e ⟧(\rho) \in RuntimeValue$$

All operators, filters, and grouping constructs are valid in any expression context, with a single, well-defined precedence hierarchy.

#### Literals

TODO:

TODO: Structured Literals and Spread

#### Operators

TODO:

#### Filters

Filters are first-class citizens integrated into the recursive structure of the grammar. They can be nested within parentheses, allowing the output of a pipeline to be used as an operand in arithmetic or comparison.

```
(x | upper) == 'FOO'
```

TODO: lambda arguments

#### Ternary Expressions

TODO:

#### Extension Types (Drops)

Drops participate in the language's semantics through structured protocols:

- **Context-Aware Coercion**: Drops use `ToLiquid` with context hints (numeric, string, boolean, etc.) to provide the most appropriate value for the current operation.
- **Behavioral Protocols**: Implementations can opt into specific protocols - **Sequence**, **Equality**, **Ordering**, and **Membership** - allowing developer-defined objects to behave like native arrays or comparable primitives without losing their internal complexity.

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

## Literals

TODO:

### Null Literal

TODO:

### Boolean Literals

TODO:

### Integer Literals

TODO:

### Float Literals

TODO:

### String Literals

TODO:

### Array Literals

TODO:

### Object Literals

### Range Literals

TODO: syntactic sugar for array of ints
TODO: optional lazy drop

## Type Conversion

Liquid performs automatic type conversions in some contexts. Here we define abstract conversion functions for runtime values, each of which is deterministic and never throws an error.

TODO: define ToObject for object literal spread

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

#### Conversion Summary Table

| Input Type             | `ToBoolean` | `ToNumber`         | `ToString`         | `ToArray` |
| ---------------------- | ----------- | ------------------ | ------------------ | --------- |
| **Nothing / Null**     | `false`     | `Nothing`          | `""`               | `[]`      |
| **Boolean**            | Identity    | `1` or `0`         | `"true"`/`"false"` | `[x]`     |
| **Number (non-zero)**  | `true`      | Identity           | String value       | `[x]`     |
| **String (non-empty)** | `true`      | Parse or `Nothing` | Identity           | `[x]`     |
| **Array (non-empty)**  | `true`      | `Nothing`          | JSON String        | Identity  |

### Truthiness and ToBoolean(x)

The language adopts structural truthiness. Empty strings, empty arrays, empty objects, zero numbers, null, and absence (`Nothing`) are falsy. All other values are truthy. This rule is uniform across value types and does not depend on host-language semantics.

Conditions are evaluated by first evaluating the condition expression and then applying `ToBoolean` to the result.

The abstract operation `ToBoolean` is defined to be identical to `IsTruthy`.

```
ToBoolean, IsTruthy : RuntimeValue → Boolean
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

## Operators

The following table lists operators from lowest to highest precedence. Operators within the same group are evaluated left-to-right (left-associative).

| Precedence   | Operator Type             | Syntax                                             |
| ------------ | ------------------------- | -------------------------------------------------- |
| 1 (Lowest)   | **Ternary**               | `consequence if condition else alternative`        |
| 2            | **Pipe (Filter)**         | `expr \| filter`                                   |
| 3            | **Nothing Coalesce**      | `??`                                               |
| 4            | **Logical OR**            | `or`                                               |
| 5            | **Logical AND**           | `and`                                              |
| 6            | **Logical NOT**           | `not`                                              |
| 7            | **Comparison/Membership** | `==`, `!=`, `<`, `>`, `<=`, `>=`, `contains`, `in` |
| 8            | **Additive**              | `+`, `-`                                           |
| 9            | **Multiplicative**        | `*`, `/`, `%`                                      |
| 10           | **Unary**                 | `+`, `-` (Positive/Negative)                       |
| 11 (Highest) | **Primary**               | Literals, Variables, `( expr )`                    |

### Conditional and Logical Operators

#### Ternary Expressions

The ternary operator `consequence if condition else alternative` provides inline branching.

- **Evaluation:** The `condition` is evaluated first and converted via `ToBoolean`.

- **Short-circuiting:** Only the branch corresponding to the truthiness of the condition is evaluated; the other branch MUST NOT be evaluated.

- **Recursive Binding:** While `ternary_expr` has the lowest precedence, its components (`consequence`, `alternative`) are bound to `pipe_expr`, allowing pipelines to exist within either branch without parentheses.

The ternary operator binds to the nearest expression. Inside filter arguments, it applies to the argument, not the filter chain.

#### Logical `and` / `or` / `not`

These operators handle boolean logic but return the **last evaluated operand** rather than a strict boolean, allowing them to act as value selectors.

- **Short-circuiting:** `and` returns the first falsy value or the last value; `or` returns the first truthy value or the last value.

- **Not:** `not` always returns a strict `Boolean` result by negating the `ToBoolean` result of its operand.

### Comparison Operators

Comparison is **total**; if two types are fundamentally incomparable and no protocol is present, the result is `false` rather than an error.

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

Membership tests (`contains` and `in`) determine whether a value appears in a container. Semantics are:

1. If `container` is a `Drop` and implements `Contains`, call `container.Contains(element)`. If it returns `Boolean`, use that value; if it returns `Nothing`, treat as `false`.
2. Else if `container` is an `Array` or a `Sequence`: iterate its elements and compare each element to `element` using `==`. If any element compares equal then the result is `true`, otherwise `false`.
3. Else if `container` is an `Object`: membership tests whether there exists a key equal to the `element` when the `element` is converted to `String` (or compared structurally to the keys as implementation prefers). Typical implementations coerce `element` to `String` and test key presence.
4. Else if `container` is a `String` and `element` is a `String`: `contains` tests substring inclusion; `in` with swapped operands follows the same rule.
5. Otherwise, coerce `container` via `ToLiquid(…, default)` and retry from the top. If no rule applies, return `false`.

`in` is defined as `element in container` (i.e. RHS is the container). Both `contains` and `in` produce a `Boolean` result.

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

A filter is a **named total function** registered in the environment.

Formally:

```
FilterEnv : Identifier → FilterFunction
```

Where:

```
FilterFunction : RuntimeValue × List<RuntimeValue> → RuntimeValue
```

The pipe operator `|` represents function application, where the expression on the left is passed as the first argument to the filter on the right.

```
expr | filter1: a, b | filter2: c
```

is equivalent to nested function calls where the previous expression is passed as the first argument to the next filter:

```
filter2(filter1(expr, a, b), c)
```

### Well-Typed Filters

Filters are total functions over `RuntimeValue`. Implementations MAY associate optional type metadata with filter definitions to enable tooling, static diagnostics, or documentation. Such metadata MUST NOT alter runtime semantics.

#### Filter Signatures

An implementation MAY register a signature for a filter:

```
FilterSignature =
  parameters: List<ParameterSpec>
  returns: ReturnSpec
```

Where:

```
ParameterSpec =
  hint: ContextHint
  optional: Boolean
  variadic: Boolean
  accepts_lambda: Boolean

ReturnSpec =
  hint: ContextHint
```

- `hint` specifies the coercion context used when preparing the argument.
- `optional` indicates that the argument may be omitted.
- `variadic` indicates that zero or more additional arguments are accepted.
- `accepts_lambda` indicates that the argument position accepts a lambda expression without immediate evaluation.
- `returns.hint` specifies the intended result category for documentation or tooling; it does not affect runtime coercion.

If no signature metadata is provided, all arguments are treated as:

```
hint = default
optional = true
variadic = false
accepts_lambda = false
```

#### Argument Evaluation and Coercion

Given:

```
expr | f : a1, a2, ..., an
```

Evaluation proceeds as follows:

1. Evaluate `expr` to `v0`.
2. Evaluate each argument expression `ai` left-to-right to produce `vi`, unless the corresponding parameter is declared `accepts_lambda`, in which case the lambda is passed as a callable value without evaluation.
3. For each parameter with a declared `hint`, coerce the corresponding argument using:

   ```
   vi' = ToLiquid(vi, hint)
   ```

   or the corresponding abstract conversion (`ToNumber`, etc.) as defined by the hint.

4. Invoke the filter function with:

   ```
   f(v0, v1', v2', ..., vk')
   ```

Coercion MUST be total. If coercion for any argument yields `Nothing`, the filter invocation MUST return `Nothing` unless the filter explicitly defines alternate behavior for `Nothing`.

#### Arity Mismatch

Filters are total and MUST NOT raise errors due to incorrect arity.

Let:

- `m` be the number of declared parameters (excluding variadic),
- `n` be the number of provided arguments.

Arity handling rules:

1. **Too Few Arguments**
   - If a required (non-optional, non-variadic) parameter has no corresponding argument, the filter invocation evaluates to `Nothing`.

2. **Too Many Arguments**
   - If extra arguments are supplied and the filter does not declare a variadic parameter, the filter invocation evaluates to `Nothing`.

3. **Variadic Parameters**
   - If a variadic parameter is declared, all remaining arguments are collected into a list and passed as separate positional arguments or as an array, according to the implementation’s calling convention.
   - Variadic parameters may accept zero arguments.

Under no circumstances does arity mismatch produce a runtime error.

#### Polymorphism

Filters MAY be polymorphic. A filter MAY define behavior for multiple categories of input values.

For example, a filter `length` MAY accept:

- `String`
- `Array`
- `Object`
- `Drop` implementing the `Sequence` protocol

If a filter receives a value outside the categories it supports, it MUST return a defined result. The recommended behavior is to return `Nothing`, though filters MAY instead return another deterministic value (e.g., `0`) if documented.

Polymorphism does not imply static type checking. Any type metadata associated with a filter is advisory and MAY be used for diagnostics, but runtime semantics remain governed solely by the total evaluation rules of this specification.

#### Totality Requirement

All filter functions MUST satisfy:

```
FilterFunction : RuntimeValue × List<RuntimeValue> → RuntimeValue
```

For every possible input tuple, a filter MUST return a `RuntimeValue` and MUST NOT raise an exception.

If a filter implementation encounters an internal failure or unsupported input combination, it MUST return `Nothing`.

## Variables and Paths

Variable resolution proceeds as follows:

- A bare `name` is looked up in the current environment (local/context variables). If present, that value is returned.
- If the path contains segments (e.g. `a.b[c].d`), evaluate each selector in sequence. For a dotted segment `.name` perform a lookup as an object key or a property access on the current value; for a bracketed selector `[expr]` evaluate `expr` and use the resulting value as the key or index (strings and numbers are commonly used as keys/indices).
- If an intermediate segment yields `Nothing`, subsequent segments evaluate to `Nothing` and the whole path yields `Nothing`.
- Accessing a missing key on an object yields `Nothing` (not an error).
- Numeric indices on arrays use `ToNumber` for the selector, and out‑of‑range accesses yield `Nothing`.

Implementations SHOULD treat property access on host objects according to a well‑documented resolution order (e.g. keys first, then methods) and MUST avoid raising exceptions during lookup - missing or inaccessible values map to `Nothing`.

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
