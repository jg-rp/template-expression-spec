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
  | Array<EvalValue>
  | Object<String → EvalValue>
```

And `EvalValue` describes the result of evaluating an expression.

```
EvalValue =
    DataValue
  | Nothing
```

The special `Nothing` type indicates the absence of a value and is distinct from `Null` (or implementation-specific `nil`, `None`, `undefined` etc.). `Nothing` may appear within composite values. Its behavior is defined uniformly wherever `EvalValue` is accepted.

### Total Evaluation

Evaluation never fails. Evaluating any expression always produces either a data value or `Nothing`. Every operator, filter, and conversion must produce a value for every possible input.

Formally, expressions are a closed algebra over `EvalValue`. For every expression `e` and environment `ρ`:

```
⟦ e ⟧(ρ) ∈ EvalValue
```

Every syntactically valid expression evaluates to a value and does not raise an error at render time.

### Extension Types

In addition to the core value space, the implementation may expose developer-defined objects known as Drops. A Drop is not itself a data value in the language. Instead, it is an object that can be coerced into an evaluation value when required, possibly using a context hint such as numeric or string context.

TODO:

`HostValue` is an implementation-defined runtime value. Each `HostValue` must be representable as an EvalValue via the language’s evaluation rules.

```
HostValue =
    EvalValue
  | Drop
```

A Drop may define context-sensitive conversions that determine how it behaves in numeric, string, or boolean contexts. Whenever evaluation requires a `DataValue`, if the operand is a Drop:

```
ToLiquid : Drop × ContextHint → EvalValue
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

The abstract operation `ToBoolean` is defined to be identical to `IsTruthy`. Boolean coercion in all contexts (including conditional evaluation and logical operators) uses the structural truthiness rules defined by IsTruthy.

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

## Equality

TODO:
