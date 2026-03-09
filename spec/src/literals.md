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
