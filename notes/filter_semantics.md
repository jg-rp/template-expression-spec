## Semantics of Filters

Filters in this grammar are not merely decorative suffixes; they represent a formal mechanism for functional transformation. By treating filters as first-class citizens, the language allows for deeply nested and highly expressive data pipelines.

### 1. Functional Desugaring

Syntactically, a filter pipeline like `input | f1: a | f2: b` is a more readable way to express nested function applications. Internally, the engine desugars these into a sequence where the result of the previous expression becomes the primary (first) argument of the next.

```liquid
# This expression:
"hello" | append: " world" | upcase

# Desugars to:
upcase(append("hello", " world"))

```

### 2. Argument Evaluation Flow

When a filter is invoked, the engine follows a strict evaluation order for its parameters:

- **Left-to-Right Execution**: All arguments—whether positional or keyword-based—are evaluated from left to right before the filter logic itself is executed.

- **Keyword Arguments**: The grammar supports `key: value` or `key=value` syntax. These allow filters to accept optional or named parameters without relying on strict positional order.

- **Evaluation Context**: Each argument is an `arg_expr`, which can itself be a complex calculation or another (parenthesized) filtered expression.

### 3. Lambda Capture and Higher-Order Filters

One of the most advanced features of this grammar is the `lambda_expr`. Unlike standard arguments, lambdas are not evaluated during the initial argument pass.

- **Lazy Execution**: A lambda (e.g., `x => x.price`) is captured as a "callable object" and passed into the filter.

- **Filter Control**: The filter implementation decides when, how often, and with what scope to execute the lambda. This enables functional primitives like `map`, `filter`, and `sort_by` to operate on collection elements dynamically.

- **Argument Scoping**: Lambdas can take single or multiple arguments (e.g., `(acc, val) => acc + val`), allowing for complex reduction logic.

### 4. Parameter Coercion and Hints

To maintain the **Total Evaluation** guarantee, filters do not receive "raw" data. Instead, arguments are coerced based on the filter's specific requirements:

- **Default Hint**: Unless a filter specifies otherwise, arguments are coerced using `ToLiquid(..., default)` to ensure they are valid `DataValues`.

- **Strict Typing**: If a filter documents a specific need (e.g., a numeric limit), the engine applies the corresponding hint (like `numeric`) before the filter sees the value.

- **Nothing Propagation**: If a required argument evaluates to `Nothing`, the filter may choose to return `Nothing` immediately, preserving the chain's safety.

---
