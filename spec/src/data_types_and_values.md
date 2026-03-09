# Data Types and Values

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

## Numeric Types

`Number` represents a decimal numeric value with arbitrary precision and exact decimal semantics.

Implementations MUST perform numeric operations using a decimal arithmetic model. Binary floating-point (e.g., IEEE-754 double) MUST NOT be used as the semantic numeric model.

An implementation MAY use binary floating-point internally, but observable behavior MUST match exact decimal arithmetic.

Integer values are a subset of `Number`. A number is considered an integer when its decimal representation has no fractional component.

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

## Extension Types (Drops)

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

## Sequence protocol

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

## Equality Protocol

A Drop MAY implement the `Equality` protocol for interaction with `==` and `!=` operators, without first coercing to a data value.

```
Equals : Drop × RuntimeValue → Boolean | Nothing
```

A Drop implements the `Equality` protocol if it supports:

```
Equals(x) -> Boolean | Nothing
```

`equals` MUST NOT throw an error.

## Ordering Protocol

A Drop MAY implement the `Ordering` protocol for interaction with `<`, `>`, `<=`, and `>=` operators, without first coercing to a data value.

```
LessThan : Drop × RuntimeValue → Boolean | Nothing
```

A Drop implements the `Ordering` protocol if it supports:

```
LessThan(x) -> Boolean | Nothing
```

## Membership Protocol

A Drop MAY implement the `Membership` protocol for interaction with `in` and `contains` operators, without first coercing to a data value.

```
Contains : Drop × RuntimeValue → Boolean | Nothing
```

A Drop implements the `Membership` protocol if it supports:

```
Contains(x) -> Boolean | Nothing
```
