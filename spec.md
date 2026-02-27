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
  | Array
  | Object
```

And `EvalValue` describes the result of evaluating an expression.

```
EvalValue =
    DataValue
  | Nothing
```

The special `Nothing` type indicates the absence of a value and is distinct from `Null` (or implementation-specific `nil`, `None`, `undefined` etc.).

Evaluation never fails. Evaluating any expression always produces either a data value or `Nothing`. Every operator, filter, and conversion must produce a value for every possible input.

Formally, expressions are a closed algebra over `EvalValue`. For every expression `e` and environment `ρ`:

```
⟦ e ⟧(ρ) ∈ EvalValue
```

Expressions have _total evaluation_. Every syntactically valid expression evaluates to a value and does not raise an error at render time.

### Extension Types

In addition to the core value space, the implementation may expose developer-defined objects known as Drops. A Drop is not itself a data value in the language. Instead, it is an object that can be coerced into an evaluation value when required, possibly using a context hint such as numeric or string context.

A Drop may define context-sensitive conversions that determine how it behaves in numeric, string, or boolean contexts. Whenever evaluation requires a `DataValue`, if the operand is a Drop:

```
to_liquid : Drop × ContextHint → EvalValue
```

## Type Conversion

TODO: Primitive conversion functions

## Predicates

TODO:
