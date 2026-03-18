## Operators

The following table lists operators from highest to lowest precedence. Operators within the same group are evaluated left-to-right (left-associative).

| Operator Type             | Syntax                                             |
| ------------------------- | -------------------------------------------------- |
| **Primary**               | Literals, Variables, `( expr )`                    |
| **Unary**                 | `+`, `-` (Positive/Negative)                       |
| **Multiplicative**        | `*`, `/`, `%`                                      |
| **Additive**              | `+`, `-`                                           |
| **Pipe (Filter)**         | `expr \| filter`                                   |
| **Comparison/Membership** | `==`, `!=`, `<`, `>`, `<=`, `>=`, `contains`, `in` |
| **Logical NOT**           | `not`                                              |
| **Logical AND**           | `and`                                              |
| **Logical OR**            | `or`                                               |
| **Nothing Coalesce**      | `orElse`                                           |
| **Ternary**               | `consequence if condition else alternative`        |

### Ternary Expressions

#### Syntax

The ternary expression follows a "Python-style" postfix conditional syntax.

```peg
TernaryExpression ← CoalesceExpression ( "if" !C CoalesceExpression "else" !C CoalesceExpression )?
```

The keywords `if` and `else` are followed by a negative lookahead `!C` to ensure they are not parsed as prefixes of identifiers.

#### Semantics

Ternary expressions allow for branching logic within a single line. They prioritize the "happy path" by placing the consequence first.

1. The **Condition** (`CoalesceExpression`) is evaluated first.
2. The result is coerced to a Boolean via **ToBoolean(x)**.
3. If `true`, the **Consequence** is evaluated and returned; the alternative is short-circuited.
4. If `false`, the **Alternative** is evaluated and returned; the consequence is short-circuited.

#### Examples

TODO: better examples

| Expression                         | Evaluation  | Notes                                                    |
| ---------------------------------- | ----------- | -------------------------------------------------------- |
| `"Hi" if true else "Bye"`          | `"Hi"`      | Basic usage.                                             |
| `a if b else c if d else e`        | **Invalid** | Syntax error: `c if d else e` is not a `PipeExpression`. |
| `a if b else (c if d else e)`      | —           | Valid: Parentheses restore the `Expression` context.     |
| `'a' \| upcase if true else 'b'`   | `"A"`       |                                                          |
| `'a' if false else 'b' \| upcase`  | `"B"`       |                                                          |
| `('a' if true else 'b') \| upcase` | `"A"`       |                                                          |

### Nothing Coalescing Operator

#### Syntax

The Nothing coalescing operator (`orElse`) is a binary operator used to provide a fallback for unresolved paths or missing data.

```peg
CoalesceExpression ← OrExpression ( S "orElse" !C S OrExpression )*
```

#### Semantics

The `orElse` operator evaluates its operands from left to right and returns the first value that is not `Nothing`.

The operator triggers a fallback **only** if the left-hand side evaluates to `Nothing` (the signal for a failed resolution or non-existent variable). If the left-hand side is any value other than `Nothing` (including `false`, `0`, or `""`), the right-hand side is not evaluated.

`orElse` binds more loosely than logical `or`, meaning `a or b orElse c` is evaluated as `(a or b) orElse c`.

And `orElse` operator binds more tightly than the pipe operator (`|`), so `a orElse b | f` is evaluated as `(a orElse b) | f`.

#### Examples

Given a context: `{"id": 0, "status": null}`

| Expression                      | Evaluation   | Notes                                        |
| ------------------------------- | ------------ | -------------------------------------------- |
| `id orElse 1`                   | `0`          | `0` is not `Nothing`.                        |
| `status orElse "active"`        | `null`       | `null` is valid data; no fallback.           |
| `missing_var orElse "fallback"` | `"fallback"` | `Nothing` triggers the fallback.             |
| `user.profile.id orElse 1`      | `1`          | Failed path resolution results in `Nothing`. |
| `null orElse "fallback"`        | `null`       | Consistent with the "Null is Data" rule.     |

### Logical Operators

#### Syntax

Logical operators perform boolean algebra and support short-circuit evaluation.

```peg
OrExpression     ← AndExpression ( S "or" !C S AndExpression )*
AndExpression    ← PrefixExpression ( S "and" !C S PrefixExpression )*
PrefixExpression ← NotExpression / TestExpression
NotExpression    ← "not" !C S PrefixExpression
```

#### Semantics

Logical operators rely on the $IsTruthy(x)$ abstract function to evaluate operands (see @sec:truthy).

`or` returns the first **truthy** operand. If all operands are falsy, it returns the result of the last operand. Short-circuits if a truthy value is found.

`and` returns the first **falsy** operand. If all operands are truthy, it returns the result of the last operand. Short-circuits if a falsy value is found.

`not` is a unary operator that returns `true` if the operand is falsy, and `false` if the operand is truthy.

#### Examples

| Expression             | Evaluation   | Notes                                                          |
| ---------------------- | ------------ | -------------------------------------------------------------- |
| `true or false`        | `true`       | Standard boolean logic.                                        |
| `null or "default"`    | `"default"`  | `null` is falsy.                                               |
| `0 or "fallback"`      | `"fallback"` | `0` is falsy.                                                  |
| `"hi" and true`        | `true`       | `"hi"` is truthy; `and` returns the last value.                |
| `missing_var and true` | `Nothing`    | `Nothing` is falsy; `and` returns the first falsy value found. |
| `not null`             | `true`       | `null` is falsy, so `not null` is `true`.                      |
| `not 0`                | `true`       | `0` is falsy.                                                  |

### Comparison Operators

#### Syntax

Comparison operators `==`, `!=`, `<=`, `>=`, `<`, `>` test for equality and ordering.

```peg
TestExpression ← PipeExpression ( S TestOperator S PipeExpression )?
TestOperator   ← "==" / "!=" / "<=" / ">=" / "<" / ">" / ("in" !C) / ("contains" !C)
```

#### Semantics

Comparison is **total**; if two types are fundamentally incomparable and no protocol is present, the result is `false` rather than an error.

$$
==, !=, <, >, <=, >= : RuntimeValue × RuntimeValue → Boolean
$$

We first define `==` and `<`, then `!=`, `>`, `<=` and `>=` in terms of `==` and `<`.

A comparison using the operator `==` evaluates to true if the comparison is between:

- `Nothing` and `Nothing`.
- two values that represent the same data.
- arrays of the same length where each element of the first array is equal to the corresponding element in the second array.
- objects with the same collection of names and, for each of those names, the associated values are equal.
- drops:
  1. If `a` is a drop and implements $Equals$ and `a.Equals(b)` is true.
  2. If `b` is a drop and implements $Equals$ and `b.Equals(a)` is true.
  3. Otherwise coerce both via $ToLiquid(…, data)$ and compare the results.

A comparison using the operator `<` yields true if the comparison is between values that are both numbers, both strings or either is a $Drop$ and that satisfy the comparison:

- For numbers: numeric ordering is used. Integers and floating values are compared by their numeric value; implementations may use a single representation (e.g. IEEE 754 BigDecimal) but comparisons must behave as the mathematical numeric ordering (smaller → less-than).
- For strings: by default strings are ordered by Unicode scalar (code point) order. Implementations MAY provide an option to use the Unicode Collation Algorithm (UCA) for locale sensitive ordering, but the canonical spec semantics are Unicode code point ordering to ensure deterministic results.
- For drops:
  1. If `a` is `Drop` and implements `LessThan` and `a.LessThan(b)` is true.
  2. If `b` is `Drop` and implements `LessThan` and `b.LessThan(a)` is true.
  3. Otherwise coerce both via $ToLiquid(…, data)$ and attempt standard ordering on the results.

`!=`, `>`, `<=` and `>=` are defined in terms of `==` and `<`.

$$
\begin{aligned}
x \;\texttt{!=}\; y &\to \text{not}(x \;\texttt{==}\; y) \\
x \;\texttt{>}\; y  &\to y \;\texttt{<}\; x \\
x \;\texttt{<=}\; y &\to (x \;\texttt{<}\; y) \;\text{or}\; (x \;\texttt{==}\; y) \\
x \;\texttt{>=}\; y &\to (y \;\texttt{<}\; x) \;\text{or}\; (x \;\texttt{==}\; y)
\end{aligned}
$$

#### Examples

| Expression     | Evaluation | Notes                                          |
| -------------- | ---------- | ---------------------------------------------- |
| `0 == 0.0`     | `true`     | Numeric normalization.                         |
| `"" == null`   | `false`    | Different types, both are falsy but not equal. |
| `5 > "2"`      | `false`    | Type mismatch defaults to `false`.             |
| `(1 + 1) == 2` | `true`     | Arithmetic is resolved before comparison.      |

### Membership Operators

#### Syntax

```peg
TestExpression ← PipeExpression ( S TestOperator S PipeExpression )?
TestOperator   ← "==" / "!=" / "<=" / ">=" / "<" / ">" / ("in" !C) / ("contains" !C)
```

#### Semantics

Membership operators `in` and `contains` determine whether a value appears in a container. Both operators return $Boolean$.

- `element in container`
- `container contains element`

These forms are semantically equivalent with operands reversed.

Evaluation proceeds as follows.

1. If `container` is a `Drop` that implements the $Membership$ protocol, call `contains(element)`:
   - If the result is `Boolean`, return that value.
   - If the result is `Nothing`, continue evaluation.
2. If `container` and element are both $String$:
   - Test for substring inclusion. Return `true` if `element` occurs within `container`, otherwise `false`.
3. If `container` is an `Object`, membership tests for the existence of a key.
   - Return `true` if `key` exists in the object, otherwise `false`.
4. Otherwise coerce to an iterable using $ToIterable$ and iterate the resulting sequence.
   - Return `true` if `key` exists in the sequence, otherwise `false`.

#### Examples

| Expression           | Evaluation | Notes                                    |
| -------------------- | ---------- | ---------------------------------------- |
| `3 in [1,2,3]`       | `true`     | Array is iterable.                       |
| `3 in (1..5) `       | `true`     | Range literals are iterable.             |
| `5 in 5`             | `true`     | `5` is coerced to `[5]` by $ToIterable$. |
| `"a" in "cat"`       | `true`     | Substring membership.                    |
| `"name" in {name:1}` | `true`     | Object property membership.              |
