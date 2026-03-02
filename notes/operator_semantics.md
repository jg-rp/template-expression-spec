## Operator Semantics

This section defines the behavior and precedence of operators within the expression language. Following the principle of **Total Evaluation**, all operators are guaranteed to return a `RuntimeValue` (often `Nothing` in error cases) rather than raising exceptions.

### 1. Precedence and Associativity

The following table lists operators from lowest to highest precedence. Operators within the same group are evaluated left-to-right (left-associative).

| Precedence   | Operator Type             | Syntax                                             |
| ------------ | ------------------------- | -------------------------------------------------- |
| 1 (Lowest)   | **Ternary**               | `consequence if condition else alternative`        |
| 2            | **Pipe (Filter)**         | `expr \| filter`                                   |
| 3            | **Null Coalesce**         | `??`                                               |
| 4            | **Logical OR**            | `or`                                               |
| 5            | **Logical AND**           | `and`                                              |
| 6            | **Logical NOT**           | `not`                                              |
| 7            | **Comparison/Membership** | `==`, `!=`, `<`, `>`, `<=`, `>=`, `contains`, `in` |
| 8            | **Additive**              | `+`, `-`                                           |
| 9            | **Multiplicative**        | `*`, `/`, `%`                                      |
| 10           | **Unary**                 | `+`, `-` (Positive/Negative)                       |
| 11 (Highest) | **Primary**               | Literals, Variables, `( expr )`                    |

---

### 2. Conditional and Logical Operators

#### Ternary Expressions

The ternary operator `consequence if condition else alternative` provides inline branching.

- **Evaluation:** The `condition` is evaluated first and converted via `ToBoolean`.

- **Short-circuiting:** Only the branch corresponding to the truthiness of the condition is evaluated; the other branch MUST NOT be evaluated.

- **Recursive Binding:** While `ternary_expr` has the lowest precedence, its components (`consequence`, `alternative`) are bound to `pipe_expr`, allowing pipelines to exist within either branch without parentheses.

#### Logical `and` / `or` / `not`

These operators handle boolean logic but return the **last evaluated operand** rather than a strict boolean, allowing them to act as value selectors.

- **Short-circuiting:** `and` returns the first falsy value or the last value; `or` returns the first truthy value or the last value.

- **Not:** `not` always returns a strict `Boolean` result by negating the `ToBoolean` result of its operand.

---

### 3. Comparison and Membership

Comparison is **total**; if two types are fundamentally incomparable and no protocol is present, the result is `false` rather than an error.

#### Equality (`==`, `!=`)

Equality is determined by:

1.  **Identity:** `Nothing` equals `Nothing`.

2.  **Structural Equality:** Comparing primitive values, arrays (by length and element), or objects (by keys and values).

3.  **Drop Protocol:** If either operand is a `Drop`, the `Equality` protocol is checked first (`a.Equals(b)`) before falling back to structural coercion.

#### Membership (`contains`, `in`)

Membership tests follow a specific resolution order:

- **Drop Protocol:** First, check if the container is a `Drop` implementing the `Membership` protocol.

- **Collection Search:** If an `Array` or `Sequence`, iterate and compare elements using `==`.

- **Object Keys:** If an `Object`, check if the element (coerced to `String`) exists as a key.

- **String Inclusion:** If both are `String`, perform a substring search.

---

### 4. Arithmetic and Unary Operators

Arithmetic operators utilize `ToNumber` for total evaluation.

- **Null Propagation:** If either operand results in `Nothing` after `ToNumber` conversion, the entire operation returns `Nothing`.

- **Safety:** Division by zero or modulo by zero returns `Nothing`.

- **Infix Operators:** Defined as $x \otimes y = ToNumber(x) \otimes_n ToNumber(y)$, where $\otimes$ is any arithmetic operator.

---

### 5. First-Class Filters (The Pipe)

The pipe operator `|` represents function application, where the expression on the left is passed as the first argument to the filter on the right.

- **High Precedence:** Filters bind tighter than logical or ternary operators, meaning `user.name | upcase == "ADMIN"` evaluates as `(user.name | upcase) == "ADMIN"`.

- **Argument Evaluation:** Positional and keyword arguments are evaluated left-to-right _before_ the filter is invoked.

- **Lambda Capture:** If an argument is a `lambda_expr`, it is passed as a callable object rather than being evaluated immediately, allowing the filter to execute it lazily or repeatedly.

**Would you like me to draft the "Type Conversion" section next, specifically detailing the logic for `ToBoolean` and `ToNumber` to complement these operator rules?**
