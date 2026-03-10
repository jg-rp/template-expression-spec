## Type Conversion

Automatic type conversion is performed in some contexts. Here we define abstract conversion functions for runtime values, each of which is deterministic and never throws an error.

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
