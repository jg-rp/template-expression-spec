## Extension Types (Drops)

Implementations may expose developer-defined objects known as Drops. A Drop is an object that can be coerced into a data value when required, with the help of a context hint.

$$
ToLiquid : Drop × ContextHint → RuntimeValue
$$

Where:

$$
ContextHint ∈ { default, numeric, string, boolean, array, object }
$$

Constraints:

- `ToLiquid(drop, default)` MUST return `DataValue`.
- `ToLiquid(drop, boolean)` MUST return `Boolean` or `Nothing`.
- `ToLiquid(drop, numeric)` MUST return `Number` or `Nothing`.
- `ToLiquid(drop, string)` MUST return `String` or `Nothing`.
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
| Filter arguments (general)                   | default |
| Array literal spread, eager filter arguments | array   |
| Object literal spread                        | object  |

### Sequence protocol

A Drop MAY implement the `Sequence` protocol to facilitate lazy iteration with the `for` tag or sequence aware filters.

A Drop implementing the Sequence protocol is considered a **Sequence value**.

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

### Equality Protocol

A Drop MAY implement the `Equality` protocol for interaction with `==` and `!=` operators, without first coercing to a data value.

```
Equals : Drop × RuntimeValue → Boolean | Nothing
```

A Drop implements the `Equality` protocol if it supports:

```
Equals(x) -> Boolean | Nothing
```

`equals` MUST NOT throw an error.

### Ordering Protocol

A Drop MAY implement the `Ordering` protocol for interaction with `<`, `>`, `<=`, and `>=` operators, without first coercing to a data value.

```
LessThan : Drop × RuntimeValue → Boolean | Nothing
```

A Drop implements the `Ordering` protocol if it supports:

```
LessThan(x) -> Boolean | Nothing
```

### Membership Protocol

A Drop MAY implement the `Membership` protocol for interaction with `in` and `contains` operators, without first coercing to a data value.

```
Contains : Drop × RuntimeValue → Boolean | Nothing
```

A Drop implements the `Membership` protocol if it supports:

```
Contains(x) -> Boolean | Nothing
```
