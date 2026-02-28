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

`EvalValue` describes the result of evaluating an expression. Note that `DataValue` is the subset of `EvalValue` that does not contain Nothing

```
EvalValue =
    Null
  | Boolean
  | Number
  | String
  | Array<EvalValue>
  | Object<String → EvalValue>
  | Nothing
```

`Nothing` is a first-class evaluation result and may appear within composite values. It represents the absence of a value produced during evaluation and is distinct from `Null` (or implementation-specific `nil`, `None`, `undefined` etc.).

### Total Evaluation

Evaluation never fails. Evaluating any expression always produces either a data value or `Nothing`. Every operator, filter, and conversion must produce a value for every possible input.

Formally, expressions are a closed algebra over `EvalValue`. For every expression `e` and environment `ρ`:

```
⟦ e ⟧(ρ) ∈ EvalValue
```

Every syntactically valid expression evaluates to a value and does not raise an error at render time.

### Extension Types

In addition to the core value space, the implementation may expose developer-defined objects known as Drops. A Drop is not itself a value in the language. Instead, it is an object that can be coerced into an evaluation value when required, possibly using a context hint such as numeric or string context.

```
ToLiquid : Drop × ContextHint → EvalValue
```

`HostValue` is an implementation-defined runtime value. Each `HostValue` must be representable as an EvalValue via the language’s evaluation rules.

```
HostValue =
    EvalValue
  | Drop
```

## Type Conversion

Liquid performs automatic type conversions as needed. Here we define abstract conversion functions for data values, each of which is total, deterministic and never throws an error.

```
ToBoolean  : EvalValue → Boolean
ToNumber   : EvalValue → Number   (Integer | Float)
ToString   : EvalValue → String
ToArray    : EvalValue → Array<EvalValue>
ToIterator : HostValue → Iterator | Nothing
```

### ToBoolean(x)

The abstract operation `ToBoolean` is defined to be identical to `IsTruthy`.

```
ToBoolean : EvalValue → Boolean
```

An evaluation result is truthy if it represents a non-empty, non-zero, non-null value.

| Input Type | Result        |
| ---------- | ------------- |
| Nothing    | false         |
| Null       | false         |
| Boolean    | identity      |
| Integer    | x ≠ 0         |
| Float      | x ≠ 0.0       |
| String     | length(x) > 0 |
| Array      | length(x) > 0 |
| Object     | size(o) > 0   |

### ToNumber(x)

Returns either Integer or Decimal.

```
ToNumber  : EvalValue → Number   (Integer | Float)
```

| Input Type | Result                                |
| ---------- | ------------------------------------- |
| Integer    | identity                              |
| Float      | identity                              |
| Boolean    | true → 1, false → 0                   |
| Nothing    | 0                                     |
| Null       | 0                                     |
| String     | parse numeric literal; if invalid → 0 |
| Array      | 0                                     |
| Object     | 0                                     |

### ToString(x)

```
ToString  : EvalValue → String
```

| Input Type | Result                 |
| ---------- | ---------------------- |
| String     | identity               |
| Integer    | decimal representation |
| Float      | canonical decimal      |
| Boolean    | `"true"` or `"false"`  |
| Null       | `""`                   |
| Nothing    | `""`                   |
| Array      | JSON-formatted array   |
| Object     | JSON-formatted object  |

### ToArray(x)

```
ToArray   : EvalValue → Array<EvalValue>
```

| Input Type      | Result   |
| --------------- | -------- |
| Array           | identity |
| Null            | []       |
| Nothing         | []       |
| Any other value | [x]      |

### ToIterator(x)

The abstract operation `ToIterator` operates on `HostValue`. Arrays yield iterators over their elements. Drops may provide iterators. Other values are non-iterable.

```
GetIterator : HostValue → Iterator | Nothing
```

TODO: table  
TODO: iterator over object items

## Predicates

TODO:

## Truthiness

The language adopts structural truthiness. Empty strings, empty arrays, empty objects, zero numbers, null, and absence (`Nothing`) are falsy. All other values are truthy. This rule is uniform across value types and does not depend on host-language semantics.

TODO: Condition semantics

## Operators

### Comparison Operators

Comparison operators are total and always produce a Boolean. If operands are not comparable under the operator, the result is false.

```
==, < : EvalValue × EvalValue → Boolean
```

XXX: Paraphrased from https://www.rfc-editor.org/rfc/rfc9535#section-2.3.5.2.2

We first define `==` and `<`, then `!=`, `>`, `<=` and `>=` in terms of `==` and `<`.

- A comparison using the operator `==` evaluates to true if the comparison is between:
  - `Nothing` and `Nothing`.
  - numbers, where the numbers compare equal using an implementation-specific equality.
  - equal primitive data values
  - arrays of the same length where each element of the first array is equal to the corresponding element in the second array.
  - objects with the same collection of names and, for each of those names, the associated values are equal.
- A comparison using the operator `<` yields true if and only if the comparison is between values that are both numbers or both strings and that satisfy the comparison:
  - TODO: typical number ordering
  - TODO: Unicode string ordering

`!=`, `>`, `<=` and `>=` are defined in terms of `==` and `<`.

```
x != y  = not (x == y)
x > y   = y < x
x <= y  = (x < y) or (x == y)
x >= y  = (y < x) or (x == y)
```

### Membership Operators

TODO:

### Logical Operators

TODO: short circuit, last value

### Arithmetic Operators

Arithmetic operators do not apply implicit type conversion. `+` and `*` are overloaded operators that perform string and array concatenation and repetition, respectively.

Implementations MAY provide filters whose semantics align with arithmetic operators.

#### Addition

1. If both Number → numeric addition
2. If both String → string concatenation
3. If both Array → array concatenation
4. Otherwise → Nothing

#### Subtraction

1. If both Number → numeric subtraction
2. Otherwise → Nothing

#### Multiplication

1. If both Number → numeric multiplication
2. If String and Number → string repetition
3. If Array and Number → array repetition
4. Otherwise → Nothing

#### Division

1. If both Number → numeric division, or Nothing if divide by zero.
2. Otherwise → Nothing

#### Modulus

1. If both Number → numeric remainder after division, or Nothing if divide by zero.
2. Otherwise → Nothing

#### Prefix Negation

1. Number → numeric negation
2. Otherwise → Nothing

#### Prefix Positive

1. Number → numeric negation
2. Otherwise → Nothing

## Filters

TODO: desugar

### Conversion filters

TODO:

```
("2" | number) + 3
(1 | string) + "2"
```
