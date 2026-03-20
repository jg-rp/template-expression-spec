# Appendix A. Notable Differences {.unnumbered}

This appendix highlights some of the differences between this specification and [Shopify/liquid](https://github.com/Shopify/liquid), at the time of writing.

- This specification supports arithmetic operators (`+`, `-`, `*`, `/`, `%`) directly in expressions. Arithmetic operators DO NOT default to zero when numeric coercion fails. Instead they evaluate to `Nothing`, and arithmetic expressions (along with their matching filters) evaluate to `Nothing` if either operand is `Nothing`, or when an operation is undefined (such as division or modulo by zero).

- This specification changes logical operator (`and` and `or`) precedence and adds a `not` operator. `and` is required to bind tighter than `or` and evaluation happens from left to right. Parentheses may be used for grouping: `not (a and b)`.

- This specification introduces first-class filters. Filters are no longer restricted by contextual parsing rules and can appear anywhere expressions are allowed. The pipe operator (`|`) is treated as a standard expression operator with deterministic behavior.

- This specification add support for Python-style conditional expressions:

  ```
  value if condition else alternative
  ```

  Ternary expressions are fully composable and follow defined precedence rules. They may be nested and combined with filters, arithmetic, and logical operators.

- This specification adds support for array and object literals:

  ```
  [1, 2, 3]
  { "name": user.name }
  ```

  A spread operator (`...`) allows composition of structures:

  ```
  [...items, 4]
  { ...defaults, "enabled": true }
  ```

  This enables template authors to construct collections immutably, without manipulating render context data.

- This specification adds support for scoped expressions as filter arguments. Lambda expressions capture their lexical environment and allow filters to apply custom logic such as mapping or sorting to data structures.

- This specification replaces the special `x == empty` and `x == blank` constructs with `x.empty?` and `x.blank?` predicates. Other predicates defined in the spec include `defined?` and `array?`.

- This specification removes value-returning operations such as `x.size`, `x.first` and `x.last`.
