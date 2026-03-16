## Type Conversion

Automatic type conversion is performed in some contexts. Here we define abstract conversion functions for runtime values, each of which is deterministic and never throws an error.

$$
\begin{aligned}
ToBoolean  \;&: RuntimeValue \to Boolean \\
ToNumber   \;&: RuntimeValue \to Number | Nothing \\
ToString   \;&: RuntimeValue \to String \\
ToArray    \;&: RuntimeValue \to Array\langle RuntimeValue \rangle \\
ToObject   \;&: RuntimeValue \to Object\langle String \to RuntimeValue \rangle \\
ToIterable \;&: RuntimeValue \to Sequence | Array\langle RuntimeValue \rangle \\
\end{aligned}
$$

Implicit conversions occur in the following contexts (each uses the corresponding abstract conversion function):

TODO: turn this into a table

- Arithmetic and numeric operators: `ToNumber`
- Unary `+`/`-`: `ToNumber`
- String concatenation (filters): `ToString`
- Boolean conditions used by `if`, ternary `if` expressions, `and`, `or`, and
  `not`: `ToBoolean`
- Comparisons that require primitive values: `ToLiquid(…, data)` then structural comparison; numeric comparisons use `ToNumber` when both sides are numeric or coercible to numeric.
- `for` iterable expressions: `ToArray` / `ToLiquid(…, iterable)`
- Filter arguments (general): `ToLiquid(…, data)` unless a filter documents a different required hint
- `ToArray` helper and sequence normalization: `ToArray`

### Truthiness and ToBoolean(x) {#sec:truthy}

The language adopts structural truthiness. Empty strings, empty arrays, empty objects, zero numbers, null, and absence (`Nothing`) are falsy. All other values are truthy. This rule is uniform across value types and does not depend on host-language semantics.

Conditions are evaluated by first evaluating the condition expression and then applying `ToBoolean` to the result.

The abstract operation `ToBoolean` is defined to be identical to `IsTruthy`.

$$
ToBoolean, IsTruthy : RuntimeValue → Boolean
$$

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

$$
ToNumber  : RuntimeValue → Number | Nothing
$$

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

### ToString(x) {#sec:to_string}

$$
ToString : RuntimeValue → String
$$

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

$$
ToArray : RuntimeValue → Array<RuntimeValue>
$$

| Input Type      | Result                              |
| --------------- | ----------------------------------- |
| Array           | identity                            |
| Object          | array of [key, value] pairs         |
| String          | Array<String>                       |
| Null            | []                                  |
| Nothing         | []                                  |
| Drop            | ToLiquid(x, array) or [] if Nothing |
| Any other value | [x]                                 |

#### String Semantics

If `x` is a `String`, `ToArray(x)` produces an array containing the string's Unicode scalar values in order.

$$
ToArray(String) → Array<String>
$$

Where each element is a **single Unicode scalar value encoded as a string of length 1** (not grapheme clusters).

Example:

$$
ToArray("cat")
→ ["c", "a", "t"]
$$

Unicode example:

$$
ToArray("😀a")
→ ["😀", "a"]
$$

### ToObject(x)

$$
ToObject : RuntimeValue → Object<String → RuntimeValue>
$$

| Input Type | Result                               |
| ---------- | ------------------------------------ |
| Object     | identity                             |
| Drop       | ToLiquid(x, object) or {} if Nothing |
| Any other  | {}                                   |

### ToIterable(x)

$$
ToIterable : RuntimeValue → Iterable
$$

| Input Type      | Result     |
| --------------- | ---------- |
| Sequence (Drop) | identity   |
| Any other       | ToArray(x) |
