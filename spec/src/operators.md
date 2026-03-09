# Operators

The following table lists operators from lowest to highest precedence. Operators within the same group are evaluated left-to-right (left-associative).

| Precedence   | Operator Type             | Syntax                                             |
| ------------ | ------------------------- | -------------------------------------------------- |
| 1 (Lowest)   | **Ternary**               | `consequence if condition else alternative`        |
| 2            | **Pipe (Filter)**         | `expr \| filter`                                   |
| 3            | **Nothing Coalesce**      | `??`                                               |
| 4            | **Logical OR**            | `or`                                               |
| 5            | **Logical AND**           | `and`                                              |
| 6            | **Logical NOT**           | `not`                                              |
| 7            | **Comparison/Membership** | `==`, `!=`, `<`, `>`, `<=`, `>=`, `contains`, `in` |
| 8            | **Additive**              | `+`, `-`                                           |
| 9            | **Multiplicative**        | `*`, `/`, `%`                                      |
| 10           | **Unary**                 | `+`, `-` (Positive/Negative)                       |
| 11 (Highest) | **Primary**               | Literals, Variables, `( expr )`                    |

## Conditional and Logical Operators

## Ternary Expressions

The ternary operator `consequence if condition else alternative` provides inline branching.

- **Evaluation:** The `condition` is evaluated first and converted via `ToBoolean`.

- **Short-circuiting:** Only the branch corresponding to the truthiness of the condition is evaluated; the other branch MUST NOT be evaluated.

- **Recursive Binding:** While `ternary_expr` has the lowest precedence, its components (`consequence`, `alternative`) are bound to `pipe_expr`, allowing pipelines to exist within either branch without parentheses.

The ternary operator binds to the nearest expression. Inside filter arguments, it applies to the argument, not the filter chain.

## Logical `and` / `or` / `not`

These operators handle boolean logic but return the **last evaluated operand** rather than a strict boolean, allowing them to act as value selectors.

- **Short-circuiting:** `and` returns the first falsy value or the last value; `or` returns the first truthy value or the last value.

- **Not:** `not` always returns a strict `Boolean` result by negating the `ToBoolean` result of its operand.

## Comparison Operators

Comparison is **total**; if two types are fundamentally incomparable and no protocol is present, the result is `false` rather than an error.

```
==, !=, <, >, <=, >= : RuntimeValue × RuntimeValue → Boolean
```

We first define `==` and `<`, then `!=`, `>`, `<=` and `>=` in terms of `==` and `<`.

- A comparison using the operator `==` evaluates to true if the comparison is between:
  - `Nothing` and `Nothing`.
  - numbers, where the numbers compare equal using an implementation-specific equality.
  - equal primitive data values
  - arrays of the same length where each element of the first array is equal to the corresponding element in the second array.
  - objects with the same collection of names and, for each of those names, the associated values are equal.
  - drops:
    1. If `a` is Drop and implements `Equals` and `a.Equals(b)` is true.
    2. Else if `b` is Drop and implements `Equals` and `b.Equals(a)` is true.
    3. Else:
       - Coerce both via `ToLiquid(…, default)`
       - Compare `DataValue` structurally

- A comparison using the operator `<` yields true if the comparison is between values that are both numbers or both strings and that satisfy the comparison:
  - For numbers: numeric ordering is used. Integers and floating values are compared by their numeric value; implementations may use a single representation (e.g. IEEE 754 BigDecimal) but comparisons must behave as the mathematical numeric ordering (smaller → less-than).
  - For strings: by default strings are ordered by Unicode scalar (code point) order. Implementations MAY provide an option to use the Unicode Collation Algorithm (UCA) for locale sensitive ordering, but the canonical spec semantics are Unicode code point ordering to ensure deterministic results.
- Or, if either operand is a drop:
  1. If `a` is `Drop` and implements `LessThan` and `a.LessThan(b)` is true.
  2. Else if `b` is `Drop` and implements `LessThan` and `b.LessThan(a)` is true.
  3. Else:
     - Coerce both via `ToLiquid(…, default)`
     - Attempt standard ordering

`!=`, `>`, `<=` and `>=` are defined in terms of `==` and `<`.

```
x != y  = not (x == y)
x > y   = y < x
x <= y  = (x < y) or (x == y)
x >= y  = (y < x) or (x == y)
```

## Membership Operators

Membership tests (`contains` and `in`) determine whether a value appears in a container. Semantics are:

1. If `container` is a `Drop` and implements `Contains`, call `container.Contains(element)`. If it returns `Boolean`, use that value; if it returns `Nothing`, treat as `false`.
2. Else if `container` is an `Array` or a `Sequence`: iterate its elements and compare each element to `element` using `==`. If any element compares equal then the result is `true`, otherwise `false`.
3. Else if `container` is an `Object`: membership tests whether there exists a key equal to the `element` when the `element` is converted to `String` (or compared structurally to the keys as implementation prefers). Typical implementations coerce `element` to `String` and test key presence.
4. Else if `container` is a `String` and `element` is a `String`: `contains` tests substring inclusion; `in` with swapped operands follows the same rule.
5. Otherwise, coerce `container` via `ToLiquid(…, default)` and retry from the top. If no rule applies, return `false`.

`in` is defined as `element in container` (i.e. RHS is the container). Both `contains` and `in` produce a `Boolean` result.

## Arithmetic Operators

Arithmetic operators operate on decimal numbers and return `Nothing` when numeric coercion fails or when an operation is undefined (such as division or modulo by zero).

```
+, -, *, /, % : EvalValue × EvalValue → Number | Nothing
+ , - (unary) : EvalValue → Number | Nothing
```

For any infix arithmetic operator `⊗ ∈ { +, −, *, /, % }`:

```
x ⊗ y = ToNumber(x) ⊗ₙ ToNumber(y)
```

1. If either operand is `Nothing` after `ToNumber(operand)`, the result is `Nothing`.
2. Otherwise apply numeric operator, or `Nothing` if divide by zero.

For unary prefix operators:

```
+x = ToNumber(x)
-x = - ToNumber(x)
```

1. If the operand is `Nothing` after `ToNumber(operand)`, the result is `Nothing`.
2. Otherwise apply numeric prefix operator.

Arithmetic operators MUST share semantics with their filter equivalents - `plus`, `minus`, `times`, etc.

## Division operator

Division uses **true arithmetic division**.

```
/ : RuntimeValue × RuntimeValue → Number | Nothing
```

Evaluation proceeds as follows:

1. Convert operands using `ToNumber`.

```
x' = ToNumber(x)
y' = ToNumber(y)
```

2. If either conversion yields `Nothing`, the result is `Nothing`.

3. If `y' = 0`, the result is `Nothing`.

4. Otherwise compute the decimal quotient:

```
q = x' ÷ y'
```

using the decimal arithmetic model defined in the Numeric Semantics section.

After computing `q`, the result is normalized:

If `q` is mathematically an integer (i.e. it has no fractional component), the result MUST be represented as an integer value.

Examples:

```
4 / 2  → 2
6 / 3  → 2
10 / 5 → 2
```

If the result has a fractional component, it is represented as a decimal number.

Examples:

```
3 / 2 → 1.5
5 / 2 → 2.5
```

When both operands are integers, the operation is **still true division**, not floor division.

Examples:

```
5 / 2 → 2.5
3 / 2 → 1.5
1 / 2 → 0.5
```

Some divisions produce non-terminating decimal expansions.

Example:

```
1 / 3
```

Implementations MUST compute the quotient using decimal arithmetic and MUST apply deterministic rounding as defined in the Numeric Semantics section.

## Modulo Operator

The modulo operator computes the remainder of division.

```
% : RuntimeValue × RuntimeValue → Number | Nothing
```

Evaluation proceeds as follows:

1. Convert operands using `ToNumber`.

```
x' = ToNumber(x)
y' = ToNumber(y)
```

2. If either conversion yields `Nothing`, the result is `Nothing`.

3. If `y' = 0`, the result is `Nothing`.

4. Otherwise compute the remainder using **Python-style modulo semantics**:

```
r = x' - y' * floor(x' / y')
```

Where `floor` denotes mathematical floor.

The result satisfies:

```
0 ≤ r < |y'|      if y' > 0
-|y'| < r ≤ 0     if y' < 0
```

Equivalently:

> The result has the **same sign as the divisor**.

If the result has no fractional component, it MUST be represented as an integer.

Examples:

```
5 % 2   → 1
4 % 2   → 0
-5 % 2  → 1
-1 % 2  → 1
5 % -2  → -1
-5 % -2 → -1
5.5 % 2 → 1.5
5 % 2.5 → 0.0
```
