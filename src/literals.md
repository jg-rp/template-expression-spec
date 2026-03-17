## Literals

```peg
Literal ← NumberLiteral /
          StringLiteral /
          BooleanLiteral /
          NullLiteral /
          ArrayLiteral /
          ObjectLiteral /
          RangeLiteral
```

### Null Literal

#### Syntax

The language provides two semantically indistinguishable keywords, `null` and `nil`, to support different developer preferences.

```peg
NullLiteral ← ("null" / "nil") !C
```

Note: The negative lookahead `!C` ensures that identifiers beginning with a Null keyword (e.g., `nullify`) are not incorrectly parsed as literals.

#### Semantics

The null literal represents a deliberate "empty" value within the data model. It is a concrete data value. It is distinct from `Nothing`, which is the internal signal used to represent evaluation failures, missing variables, or out-of-bounds access.

A null literal always evaluates to a value of type `Null`. In a boolean context, `Null` is always "falsy" (see @sec:truthy).

#### Examples

| Expression            | Evaluation  | Notes                                                                  |
| --------------------- | ----------- | ---------------------------------------------------------------------- |
| `null`                | `null`      | Evaluates to the Null type.                                            |
| `nil`                 | `null`      | Identical to `null`.                                                   |
| `user.id == null`     | `true`      | Returns true if `id` is explicitly null.                               |
| `(null ?? "default")` | `null`      | The coalescing operator tests for `Nothing`. `null` is a data value.   |
| `(null or "default")` | `"default"` | The logical `or` operator treats `Null` as a trigger for the fallback. |

### Boolean Literals

#### Syntax

The language recognizes the lowercase keywords `true` and `false`.

```{.peg}
BooleanLiteral ← ("true" / "false") !C
```

Note: The negative lookahead `!C` ensures that identifiers beginning with a boolean keyword (e.g., `true_value`) are not incorrectly parsed as literals.

#### Semantics

Boolean literals represent the two logical truth values. They evaluate to a value of type `Boolean`. Boolean keywords are case-sensitive. `True` or `TRUE` are not recognized as boolean literals and will be interpreted as identifiers (variable names).

The literal `true` is always "truthy," and the literal `false` is always "falsy" (see @sec:truthy).

#### Examples

| Expression        | Evaluation | Notes                                                                      |
| ----------------- | ---------- | -------------------------------------------------------------------------- |
| `true`            | `true`     | Evaluates to the Boolean `true` value.                                     |
| `false`           | `false`    | Evaluates to the Boolean `false` value.                                    |
| `not true`        | `false`    | The logical `not` operator inverts the boolean value.                      |
| `(true ?? false)` | `true`     | The null coalescing operator returns the first non-null/non-nothing value. |

### Numeric Literals

#### Syntax

Numeric literals take the form of:

- An integer part - must be either a single `0` or a non-zero digit followed by any number of digits. Leading zeros are not permitted (e.g., `05` is invalid).
- An optional fractional part - a decimal point followed by one or more digits.
- An optional exponent part using either `e` or `E`.

```peg
NumberLiteral ← Integer Fraction? Exponent? !C
Integer       ← "0" / [1-9] [0-9]*
Fraction      ← "." [0-9]+
Exponent      ← [eE] [+-]? [0-9]+
```

Syntactically, the `NumberLiteral` itself is unsigned. Negative numbers are represented by applying the unary negation operator (`-`) to a literal. See @sec:arithmetic.

#### Semantics

Regardless of the notation used (standard or scientific), all numeric literals resolve to the `Number` type and are stored using exact decimal semantics. An exponent does not "coerce" the number into a floating-point type; `1e2` and `100` are semantically and type-identical.

#### Examples

| Expression | Evaluation  | Notes                                                      |
| ---------- | ----------- | ---------------------------------------------------------- |
| `0`        | `0`         | Single zero integer.                                       |
| `42`       | `42`        | Positive integer without leading zeros.                    |
| `0.001`    | `0.001`     | Decimal fraction.                                          |
| `1.23e4`   | `12300`     | Scientific notation (positive exponent).                   |
| `5E-3`     | `0.005`     | Scientific notation (negative exponent, case-insensitive). |
| `-10.5`    | `-10.5`     | Unary negation applied to a literal.                       |
| `05`       | **Invalid** | Leading zeros are not allowed in the integer part.         |

### String Literals

#### Syntax

Both single and double quoted strings are supported. Both forms allow interpolation.

Escape sequences follow JSON syntax, with the addition of an escaped single quote for single quoted strings, and `\${` to escape string interpolation.

```peg
StringLiteral  ← DoubleQuoted / SingleQuoted

DoubleQuoted   ← "\"" (Interpolation / DoubleEscaped / Unescaped / "'")* "\""
SingleQuoted   ← "'"  (Interpolation / SingleEscaped / Unescaped / "\"")* "'"

Interpolation  ← "${" Expression "}"

DoubleEscaped  ← "\\" ( "\"" / Escapable )
SingleEscaped  ← "\\" ( "'" / Escapable )

Unescaped      ← LiteralDollar / SourceChar
LiteralDollar  ← "$" ! "{"

Escapable      ← "b" / "f" / "n" / "r" / "t" / "/" / "\\" / ("u" ~ HexChar) / "${"
HexChar        ← NonSurrogate / HighSurrogate "\\u" LowSurrogate
HighSurrogate  ← [Dd] [AaBb89] [0-9A-Fa-f]{2}
LowSurrogate   ← [Dd] [CcDdEeFf] [0-9A-Fa-f]{2}
NonSurrogate   ← [AaBbCcEeFf0-9] [0-9A-Fa-f]{3} /
                 [Dd] [0-7] [0-9A-Fa-f]{2}

SourceChar     ← " " /
                 "!" /
                 "#" /
                 "%" /
                 "&" /
                 [\u0028-\u0058] /
                 [\u005D-\uD7FF] /
                 [\uE000-\u0010FFFF]
```

#### Semantics

String literals represent sequences of Unicode scalar values (not grapheme clusters). They support both simple static text and dynamic content via interpolation.

When a string is evaluated, from left to right:

- If the segment is unescaped text, append it to the result.
- If the segment is one or more escape sequences, append decoded escape sequences to the result.
- If the segment is an expression, resolve the expression and convert it to a string using $ToString$ (@sec:to_string), and append the string to the result.

There is no semantic difference between single- and double-quoted strings beyond delimiter rules.

Invalid Unicode escape sequences make the string literal invalid at parse time.

#### Examples

| Expression          | Evaluation              | Notes                                                |
| ------------------- | ----------------------- | ---------------------------------------------------- |
| `"Hello"`           | `"Hello"`               | Simple double-quoted string.                         |
| `'Alice\'s House'`  | `"Alice's House"`       | Escaped single quote in a single-quoted string.      |
| `"Cost: $100"`      | `"Cost: $100"`          | Raw `$` is literal because it isn't followed by `{`. |
| `"Hi ${user.name}"` | `"Hi Alice"`            | Interpolates the value of `user.name`.               |
| `"Value: \${1}"`    | `"Value: ${1}"`         | Escaped `${` prevents interpolation.                 |
| `"\u00A9"`          | `"©"`                   | Unicode escape for the Copyright symbol.             |
| `"Line\nBreak"`     | A string with a newline | Standard escape sequence.                            |
| `"\uD83D\uDE00"`    | `"😀"`                  | Decoded surrogate pair.                              |

### Array Literals

#### Syntax

Array literals consist of a comma separated sequence of expressions, surrounded by square brackets.

```peg
ArrayLiteral ← "[" S (ArrayItem (S "," S ArrayItem)*)? S ","? S "]"
ArrayItem    ← SpreadExpr / Expression
SpreadExpr   ← "..." Expression
```

Trailing commas are permitted. If an array literal contains a single `StringLiteral` item, it must be followed by a comma to syntactically differentiate it from a root variable using bracket notation.

#### Semantics

An array literal constructs an immutable ordered collections of values. They are evaluated eagerly from left to right. Each `Expression` is resolved to a value and inserted into a new Array instance, $Array\langle RuntimeValue \rangle$.

Arrays are heterogenous; they may contain values of any type, including other arrays and objects.

##### The Spread Operator

The spread operator `...` allows for the expansion of an iterable into the array literal.

1. The expression following `...` is evaluated and coerced via **ToIterable(x)** (see @sec:to_iterable).
2. Each of the elements in the resulting iterable is inserted into the new array at the current position.

Note that $ToIterable$ is total; the spread operator can not fail.

#### Examples

Given a context: `{"low": [1, 2], "high": [4, 5]}`

| Expression             | Evaluation         | Notes                                                |
| ---------------------- | ------------------ | ---------------------------------------------------- |
| `[1, 2, 3]`            | `[1, 2, 3]`        | A simple array of numbers.                           |
| `[1, "two", true]`     | `[1, "two", true]` | A heterogeneous array.                               |
| `[...low, 3, ...high]` | `[1, 2, 3, 4, 5]`  | Spread operators merging two arrays with a literal.  |
| `[1, , 2]`             | **Invalid**        | Empty items between commas are not permitted.        |
| `[1, 2,]`              | `[1, 2]`           | Trailing comma is ignored.                           |
| `[...null]`            | `[]`               | `Null` is coerced to an empty array by $ToIterable$. |
| `[1, missing_var, 3]`  | `[1, Nothing, 3]`  | Arrays can contain `Nothing`.                        |

### Object Literals

#### Syntax

Object literals consist of a comma-separated sequence of key-value pairs or spread expressions, surrounded by curly braces.

```peg
ObjectLiteral ← "{" S (ObjectItem (S "," S ObjectItem)*)? S ","? S "}"
ObjectItem    ← SpreadExpr / KeyValuePair
KeyValuePair  ← ObjectKey S ":" S Expression
ObjectKey     ← Identifier / QuotedName
QuotedName    ← ( "\"" DoubleQuotedName "\"" ) / ( "'" SingleQuotedName "'" )
```

`QuotedName` follows the same escaping rules as `StringLiteral` but **does not support interpolation**. This ensures that object keys are statically determinable at parse-time.

```peg
QuotedName         ← DoubleQuotedName / SingleQuotedName

DoubleQuotedName   ← "\"" ( DoubleEscapedName / NameSourceChar / "'")* "\""
SingleQuotedName   ← "'"  ( SingleEscapedName / NameSourceChar / "\"")* "'"

DoubleEscapedName  ← "\\" ( "\"" / EscapableNameChar )
SingleEscapedName  ← "\\" ( "'" / EscapableNameChar )

EscapableNameChar  ← "b" / "f" / "n" / "r" / "t" / "/" / "\\" / ("u" ~ HexChar)

NameSourceChar     ← " " /
                     "!" /
                     "#" /
                     "$" /
                     "%" /
                     "&" /
                     [\u0028-\u0058] /
                     [\u005D-\uD7FF] /
                     [\uE000-\u0010FFFF]
```

#### Semantics

An object literal constructs an immutable collection of key-value pairs, $Object\langle String, RuntimeValue \rangle$.

The literal is evaluated eagerly from left to right. If the same key is defined multiple times (either via direct assignment or via the spread operator), the **last** value evaluated takes precedence.

Once constructed, the object and its key-set cannot be modified.

##### Key Resolution

- If a key is an `Identifier`, it is treated as a literal string (e.g., `{ name: "Alice" }` uses the string `"name"` as the key).
- If a key is a `QuotedName`, the quotes are stripped and the interior is processed for escapes to produce the string key.

##### The Spread Operator

The spread operator `...` allows for the merging of another object into the one being constructed.

1. The expression following `...` is evaluated and coerced via **ToObject(x)** (see @sec:to_object).
2. Each key-value pair in the resulting object is inserted into the new object.
3. If the value cannot be coerced into an object, the spread is ignored (as $ToObject$ is total).

#### Examples

Given a context: `{"base": {"id": 1, "role": "guest"}}`

| Expression                   | Evaluation                   | Notes                                                     |
| ---------------------------- | ---------------------------- | --------------------------------------------------------- |
| `{ name: "Bob", age: 30 }`   | `{"name": "Bob", "age": 30}` | Standard object with identifier keys.                     |
| `{ "First Name": "Bob" }`    | `{"First Name": "Bob"}`      | Quoted keys allow for whitespace and reserved characters. |
| `{ ...base, role: "admin" }` | `{"id": 1, "role": "admin"}` | The `role` key from `base` is overwritten by the literal. |
| `{ a: 1, a: 2 }`             | `{"a": 2}`                   | Last key wins rule applies.                               |
| `{ ...null, count: 0 }`      | `{"count": 0}`               | Spreading a non-object value results in an empty merge.   |
| `{ "${name}": 1 }`           | **Invalid**                  | Object keys do not support interpolation.                 |

### Range Literals

#### Syntax

Range literals consist of two expressions separated by a double-dot (`..`), enclosed in parentheses.

```peg
RangeLiteral ← "(" S Expression S ".." S Expression S ")"
```

#### Semantics

A range literal constructs an immutable, inclusive sequence of integers.

1. The `start` (left) and `end` (right) expressions are evaluated eagerly before coercing both values to numbers using $ToNumber$ (see @sec:to_number).
2. If a value is a decimal, truncate toward zero.
3. If either expression evaluates to `Nothing`, the range literal evaluates to an empty sequence.
4. The range is inclusive of both the start and end values.
5. If `start > end`, the range results in an **empty sequence**. It does not count backward.

Implementations MAY represent this value as:

1. An eager $Array\langle RuntimeValue \rangle$, or
2. A $Drop$ implementing the $Sequence$ protocol.

The observable behavior MUST be indistinguishable.

Implementations MAY define an upper limit to the number of items in a range to guard against excessively large array materialization.

#### Examples

| Expression        | Evaluation        | Notes                                                     |
| ----------------- | ----------------- | --------------------------------------------------------- |
| `(1..5)`          | `[1, 2, 3, 4, 5]` | Standard ascending inclusive range.                       |
| `(5..1)`          | `[]`              | Start is greater than end; results in empty sequence.     |
| `(1.2..3.8)`      | `[1, 2, 3]`       | Values are coerced to integers before generation.         |
| `(1..1)`          | `[1]`             | Single-item sequence.                                     |
| `(0..user.count)` | `[0, 1, 2]`       | Dynamic range (assuming `user.count` is 2).               |
| `(1..null)`       | `[]`              | `null` coerces to `Nothing`, resulting in an empty range. |
