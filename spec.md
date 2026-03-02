# A Unified Expression Grammar for Liquid Templates

This document defines a Liquid template expression syntax...

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

### Total Evaluation

Evaluation never fails. Evaluating any expression always produces a value. Every operator, filter, and conversion must produce a value for every possible input.

Formally, expressions are a closed algebra over `RuntimeValue`. For every expression `e` and environment `ρ`:

```
⟦ e ⟧(ρ) ∈ RuntimeValue
```

Every syntactically valid expression evaluates to a value and does not raise an error at render time.

## Type Conversion

Liquid performs automatic type conversions in some contexts. Here we define abstract conversion functions for runtime values, each of which is deterministic and never throws an error.

```
ToBoolean  : RuntimeValue → Boolean
ToNumber   : RuntimeValue → Number | Nothing
ToString   : RuntimeValue → String
ToArray    : RuntimeValue → Array<RuntimeValue>
```

TODO: enumerate context that do implicit type conversion.

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
ToString  : RuntimeValue → String
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
ToArray   : RuntimeValue → Array<RuntimeValue>
```

| Input Type      | Result                              |
| --------------- | ----------------------------------- |
| Array           | identity                            |
| Null            | []                                  |
| Nothing         | []                                  |
| Drop            | ToLiquid(x, array) or [] if Nothing |
| Any other value | [x]                                 |

## Predicates

TODO:

## Truthiness

The language adopts structural truthiness. Empty strings, empty arrays, empty objects, zero numbers, null, and absence (`Nothing`) are falsy. All other values are truthy. This rule is uniform across value types and does not depend on host-language semantics.

TODO: Condition semantics

## Operators

### Comparison Operators

Comparison operators are total and always produce a Boolean value. If operands are not comparable under the operator, the result is false.

```
==, < : RuntimeValue × RuntimeValue → Boolean
```

XXX: Paraphrased from https://www.rfc-editor.org/rfc/rfc9535#section-2.3.5.2.2

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
  - TODO: conventional number ordering
  - TODO: Unicode string ordering
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

TODO:

1. If `container` is Drop and implements `Contains`:

   ```
   container.Contains(element)
   ```

2. Else if container is Sequence:
   - Iterate and compare using `==`

3. Else if container is Object:
   - Membership tests key existence

4. Else:
   - Coerce container via `default`
   - Retry

5. Otherwise → Boolean false

This allows:

- Database-backed collections
- Lazy paginated results
- Efficient membership tests
- Avoid materializing huge arrays

### Logical Operators

TODO: short circuit, last value

### Arithmetic Operators

Arithmetic operators are defined in terms of numeric conversion and can produce `Nothing`. Each operand is converted to a `Number` via the total abstract function `ToNumber`.

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

TODO: desugar
