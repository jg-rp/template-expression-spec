### Arithmetic Operators {#sec:arithmetic}

#### Syntax

```peg
ArithmeticExpression ← AddExpression
AddExpression        ← MulExpression ( S ( "+" / "-" ) S MulExpression )*
MulExpression        ← UnaryExpression ( S ( "*" / "/" / "%" ) S UnaryExpression )*
UnaryExpression      ← NegExpression / PosExpression / PrimaryExpression
NegExpression        ← "-" UnaryExpression
PosExpression        ← "+" UnaryExpression
```

#### Semantics

Arithmetic is performed using the **Decimal Arithmetic Model** to ensure exact precision for base-10 decimals, avoiding the rounding errors typical of binary floating-point systems.

All arithmetic operators are total. Operands are coerced to numbers via $ToNumber$. If an operand resolves to `Nothing`, the entire arithmetic operation resolves to `Nothing`.

```
+, -, *, /, % : RuntimeValue × RuntimeValue → Number | Nothing
+ , - (unary) : RuntimeValue → Number | Nothing
```

Arithmetic operators MUST share semantics with their filter equivalents - `plus`, `minus`, `times`, etc.

##### Division operator

Division uses **true arithmetic division**. Evaluation proceeds as follows:

1. Convert operands using `ToNumber`.
2. If either conversion yields `Nothing`, the result is `Nothing`.
3. If the right hand side is equal to `0`, the result is `Nothing`.
4. Otherwise compute the decimal quotient using the decimal arithmetic model defined in @sec:numeric_types.
5. Normalize; if the result is mathematically an integer (i.e. it has no fractional component), the result MUST be represented as an integer value.

##### Modulo Operator

The modulo operator computes the remainder of division. Evaluation proceeds as follows:

1. Convert operands using $ToNumber$.
2. If either conversion yields `Nothing`, the result is `Nothing`.
3. If the right hand side is equal to `0`, the result is `Nothing`.
4. Otherwise compute the remainder using $r = x' - y' * floor(x' / y')$. The result has the **same sign as the divisor**.
5. If the result has no fractional component, it MUST be represented as an integer.

#### Examples

| Expression   | Evaluation | Notes                                                                   |
| ------------ | ---------- | ----------------------------------------------------------------------- |
| `4 / 2`      | `2`        | Integer representation.                                                 |
| `0.1 + 0.2`  | `0.3`      | Exact decimal arithmetic.                                               |
| `10 / 4`     | `2.5`      | True division (no integer truncation).                                  |
| `"Item" + 1` | `Nothing`  | `"Item"` coerces to `Nothing`. `+` is not overloaded for concatenation. |
| `10 / 0`     | `Nothing`  | Division by zero is handled safely.                                     |
| `5 * "abc"`  | `Nothing`  | Incompatible types resolve to `Nothing`.                                |
| `5 % 2`      | `1`        |                                                                         |
| `4 % 2`      | `0`        |                                                                         |
| `-5 % 2`     | `1`        |                                                                         |
| `5 % -2`     | `-1`       |                                                                         |
| `5.5 % 2`    | `1.5`      |                                                                         |
