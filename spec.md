# A Unified Expression Grammar for Templates Languages

## Abstract

This document defines a unified, implementation‑independent expression language for Liquid-style templates.

This specification focuses strictly on the internal mechanics of expressions. Notably, this document does not define the surrounding tag architecture (such as the specific implementation of `{% if %}` or `{% for %}`) nor does it provide a "standard library" of filters.

Compatibility with existing Liquid implementations is explicitly not a goal.

## Status

Draft - specification in progress. Feedback and test cases are welcome.

## Introduction

TODO:

### Terminology

- _Expression_: An expression is the fundamental unit of computation within a Liquid template, representing a sequence of identifiers, literals, and operators that resolves to a value. They appear within output delimiters to render data directly to the page (e.g., `{{ user.name | upcase }}`), inside conditional tags to govern template logic (e.g., `{% if item.price > 100 %}`), and as the data sources for iterations (e.g., `{% for product in collections.frontpage %}`)

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

TODO: String interpolation

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
ContextHint ∈ { default, numeric, string, boolean, render, array, object }
```

Constraints:

- `ToLiquid(drop, default)` MUST return `DataValue`.
- `ToLiquid(drop, boolean)` MUST return `Boolean` or `Nothing`.
- `ToLiquid(drop, numeric)` MUST return `Number` or `Nothing`.
- `ToLiquid(drop, string)` MUST return `String` or `Nothing`.
- `ToLiquid(drop, render)` MUST return `String` or `Nothing`.
- `ToLiquid(drop, array)` MUST return `Array<RuntimeValue>` or `Nothing`.
- `ToLiquid(drop, object)` MUST return `Object<String → RuntimeValue>` or `Nothing`.

The result of `ToLiquid(drop, default)` MUST be a valid `DataValue` as defined above, meaning it MUST NOT contain `Drop` at any depth.

The following table shows when each hint applies.

| Context                                      | Hint    |
| -------------------------------------------- | ------- |
| Arithmetic                                   | numeric |
| String concatenation                         | string  |
| Boolean test (`if`, `and`, `or`)             | boolean |
| Comparison                                   | default |
| Rendering `{{ x }}`                          | render  |
| Filter arguments (general)                   | default |
| Array literal spread, eager filter arguments | array   |
| Object literal spread                        | object  |

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

### Numeric Literals

Numeric literals are parsed as exact decimal values.

Examples:

```
1        → exact integer
1.0      → exact decimal
0.01     → exact decimal
```

Trailing zeros are not semantically significant:

```
1.0 == 1  → true
```

### String Literals

A string literal represents a sequence of Unicode scalar values.

String literals:

- May be delimited by single (`'`) or double (`"`) quotes.
- Support JavaScript-style escape sequences.
- Support JavaScript-style interpolation using `${expr}`.
- Are evaluated left-to-right.
- Are total and never produce `Nothing`.

Two forms are supported:

```
"double quoted"
'single quoted'
```

The delimiter determines which quote character must be escaped.

Both forms support:

- Escape sequences
- Interpolation

There is no semantic difference between single- and double-quoted strings beyond delimiter rules.

Invalid Unicode escape sequences make the string literal invalid at parse time.

#### Evaluation Model

A string literal is evaluated as a sequence of segments:

- Raw text segments
- Escape sequences
- Interpolation segments

Evaluation proceeds left-to-right.

We construct:

```
Result = ""
```

For each segment:

- if raw text segment
  1. Append literal Unicode characters to `Result`

- if escape sequences
  1. Append decoded escape sequence to `Result`.

  Escape sequences are interpreted according to JavaScript-style rules.

  Supported escapes:

  | Escape         | Meaning                  |
  | -------------- | ------------------------ |
  | `\\`           | backslash                |
  | `\"`           | double quote             |
  | `\'`           | single quote             |
  | `\n`           | line feed (U+000A)       |
  | `\r`           | carriage return (U+000D) |
  | `\t`           | tab (U+0009)             |
  | `\b`           | backspace                |
  | `\f`           | form feed                |
  | `\/`           | slash                    |
  | `\uXXXX`       | Unicode code unit        |
  | `\uXXXX\uYYYY` | surrogate pair           |
  | `\${`          | literal `${`             |

  Escape evaluation rules:
  - `\uXXXX` MUST produce the corresponding Unicode scalar value.
  - Surrogate pairs MUST be combined into a single scalar.

  Implementations MUST decode escape sequences at parse time. Invalid escape sequences MUST throw an error at parse time.

- if interpolation `${ expr }`
  1. Evaluate `expr` to `v`.
  2. Convert `v `to string `s = ToString(v)`
  3. Append `s` to `Result`

  Interpolation NEVER propagates `Nothing`. `ToString(Nothing) → ""`

##### Examples

```
"hello"
'world'

"line\nbreak"
'quote: \''
"quote: \""

"${1 + 2}"        → "3"
"${1 / 0}"        → ""

"\u0041"          → "A"
"\uD83D\uDE00"    → "😀"
```

### Array Literals

An array literal is defined as:

```
array_literal =
  "[" ~ S ~ (item ~ (S ~ "," ~ S ~ item)*)? ~ S ~ ","? ~ S ~ "]"

item =
    spread_expr
  | expr

spread_expr =
    "..." ~ expr
```

Trailing commas are permitted.

#### Evaluation Semantics

Evaluation proceeds left-to-right.

Let:

```
[ e1, e2, ..., en ]
```

Each `ei` is either:

- A normal expression
- A spread expression `...x`

We construct a result list:

```
Result = []
```

For each item in order:

- if normal item
  1. Evaluate `expr` to `v`.
  2. Append `v` to `Result` (`Nothing` is appended as a normal element).

- if spread item
  1. Evaluate `expr` to `v`.
  2. Normalize via:

     ```
     elements = ToArray(v)
     ```

  3. Append each element of `elements` to `Result`.

The final result is `Array<RuntimeValue>`. Array literals always evaluate to an eager `Array`.

### Object Literals

An object literal is defined as:

```
object_literal =
  "{" ~ S ~ (object_item ~ (S ~ "," ~ S ~ object_item)*)? ~ S ~ ","? ~ S ~ "}"

object_item =
    spread_expr
  | (quoted_name | name) ~ S ~ ":" ~ S ~ expr
```

Trailing commas are permitted.

#### Evaluation Semantics

Evaluation proceeds left-to-right.

We construct:

```
Result = {}
```

A mapping:

```
Object<String → RuntimeValue>
```

For item in order:

- if keyed property `key : expr`
  1. Evaluate `expr` → `v`.
  2. Determine key string:
  - If `quoted_name`, use literal string.
  - If `name`, use its identifier text.
  3. Insert into `Result`:

     ```
     Result[key] = v
     ```

     If the key already exists, it is overwritten.

- if spread property `...expr`
  1. Evaluate `expr` → `v`.
  2. Convert via abstract operation `ToObject`:

     ```
     source = ToObject(v)
     ```

  3. For each key-value pair in `source`:

     ```
     for (k, v) in source:
         Result[k] = v
     ```

     If the key already exists, it is overwritten.

### Range Literals

A range literal denotes a finite sequence of consecutive integers.

Syntactic form:

```
range_literal ::= "(" start ".." end ")"
```

Where:

- `start` and `end` are arbitrary expressions.
- `..` binds as a primary expression.
- Parentheses MUST be used.

Examples:

```
(1..5)
((1 + 1)..10)
(a..b)
```

#### Evaluation Semantics

A range literal is syntactic sugar for a finite integer sequence.

Evaluation proceeds as follows:

1. Evaluate `start` to `v_start`.
2. Evaluate `end` to `v_end`.
3. Apply numeric coercion:

   ```
   n_start = ToNumber(v_start)
   n_end   = ToNumber(v_end)
   ```

4. If either coercion yields `Nothing`, the range evaluates to an empty sequence.

5. Otherwise:
   - Convert both numbers to integers using implementation-defined truncation toward zero.

   - If `n_start ≤ n_end`, the sequence contains all integers `n` such that:

     ```
     n_start ≤ n ≤ n_end
     ```

   - If `n_start > n_end`, the result is an empty sequence.

A range literal never evaluates to `Nothing`. A malformed range is an empty collection, not an absent value.

An implementation MAY define an upper limit to the number of items in a range to guard against excessively large array materialization.

#### Result Representation

A range literal evaluates to a `RuntimeValue` that behaves as a finite sequence of integers.

Implementations MAY represent this value as:

1. An eager `Array<RuntimeValue>`, or
2. A `Drop` implementing the `Sequence` protocol.

The observable behavior MUST be indistinguishable.

#### Interaction with the Sequence Protocol

If a range is represented as a `Drop`, it MUST implement the `Sequence` protocol:

```
length()  → max(0, n_end - n_start + 1)
iterate() → yields each integer in increasing order
slice(offset, limit, reversed) → another range-like Drop
```

The `for` tag and any sequence-aware filters MUST:

1. First check whether the value implements the `Sequence` protocol.
2. If so, use `length()` and `iterate()` directly.
3. Otherwise, fall back to `ToArray`.

This ensures that lazy range implementations are not forced into eager materialization.

#### Interaction with Filters and Operators

Because a range evaluates to a sequence value, it:

- May be piped into filters.
- May be compared structurally.
- May be used with `contains` / `in`.
- May be passed to `ToArray`.

Examples:

```
(1..5) | length
3 in (1..5)
(1..5) == [1,2,3,4,5]
```

All such expressions MUST behave identically regardless of eager or lazy representation.

## Type Conversion

Liquid performs automatic type conversions in some contexts. Here we define abstract conversion functions for runtime values, each of which is deterministic and never throws an error.

```
ToBoolean  : RuntimeValue → Boolean
ToNumber   : RuntimeValue → Number | Nothing
ToString   : RuntimeValue → String
ToArray    : RuntimeValue → Array<RuntimeValue>
ToObject   : RuntimeValue → Object<String → RuntimeValue>
```

Implicit conversions occur in the following contexts (each uses the corresponding abstract conversion function):

TODO: turn this into a table

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

### ToObject(x)

```
ToObject : RuntimeValue → Object<String → RuntimeValue>
```

| Input Type | Result                               |
| ---------- | ------------------------------------ |
| Object     | identity                             |
| Drop       | ToLiquid(x, object) or {} if Nothing |
| Any other  | {}                                   |

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

Filters that are unknown to the environment evaluate to `Nothing`. Implementations MAY throw an error or warning at parse time in the even of an unknown filter.

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

## Numeric Semantics

### Number Type

`Number` represents a decimal numeric value with arbitrary precision and exact decimal semantics.

Implementations MUST perform numeric operations using a decimal arithmetic model. Binary floating-point (e.g., IEEE-754 double) MUST NOT be used as the semantic numeric model.

An implementation MAY use binary floating-point internally, but observable behavior MUST match exact decimal arithmetic.

### Decimal Arithmetic Model

The language defines numbers using base-10 decimal semantics:

- Exact representation of finite decimal literals.
- Exact addition, subtraction, and multiplication.
- Exact division when representable as a finite decimal.
- Deterministic rounding when required.

This ensures:

```
0.1 + 0.2 == 0.3   → true
```

in all conforming implementations.

Implementations MUST NOT introduce binary floating-point rounding artifacts.

Example (required behavior):

```
0.1 + 0.2
```

MUST evaluate to a number equal to decimal `0.3`.

It MUST NOT produce:

```
0.30000000000000004
```

### Division Semantics

Division may produce a non-terminating decimal expansion.

Example:

```
1 / 3
```

TODO: Loosen precision requirements

Implementations MUST use decimal division with a minimum precision of 28 decimal digits and MUST round using round-half-even (banker’s rounding), unless a higher precision is supported.

The precision used MUST be consistent within an evaluation.

### Numeric Equality

Numeric equality is mathematical equality after decimal normalization.

Examples:

```
1 == 1.0        → true
0.30 == 0.3     → true
```

### String Conversion

`ToString(Number)` MUST produce a canonical decimal representation:

- No scientific notation.
- No unnecessary trailing zeros.
- No trailing decimal point.

TODO: true division
TODO: no decimal point when operands are integers and result is whole

Examples:

```
1       → "1"
1.0     → "1"
0.300   → "0.3"
1000    → "1000"
```
