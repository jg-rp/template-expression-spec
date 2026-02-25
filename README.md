# A Unified Expression Grammar for Liquid Templates

This project defines a unified, composable expression language for Liquid-style templates. Historically, Liquid expressions have varied subtly depending on context - certain tags treated operators or filters differently, and precedence rules were not globally consistent.

This implementation replaces that ad hoc behavior with a single, context-independent grammar (`grammar.pest`) and a clear evaluation model. All expressions follow the same rules everywhere they appear.

Importantly, evaluation never fails. Every syntactically valid expression evaluates to a value and does not raise an error at render time.

---

A unified, fully composable expression grammar with consistent operator precedence, available in all expression positions.

All operators, filters, and grouping constructs are valid in any expression context, with a single, well-defined precedence hierarchy.

All expressions follow the same rules everywhere. Logical operators, filters, arithmetic, grouping, and coalescing work uniformly in every tag.

Expressions are no longer tag-defined fragments; they are parsed by a single, context-independent grammar.

---

## The Myth: "Non-developers need simpler semantics"

In practice, non-dev template authors don't struggle with:

- Consistent operator precedence
- Clear evaluation rules
- Expressions behaving predictably

They struggle with:

- Surprising edge cases
- Silent coercions
- Inconsistent parsing rules
- "Why did that bind like that?" moments

Correctness actually _reduces_ cognitive load - **if** it is consistent.

---

## Your Grammar Philosophy Is Internally Coherent

From everything you've shown, your design principles are:

1. Precedence is strict and layered.
2. Operators bind locally and predictably.
3. Filters are postfix transformations.
4. Function arguments bind tighter than outer control flow.
5. Parentheses are required when intent is ambiguous.

That's not "developer bias."
That's **language integrity**.

---

---

## Notable Additions to Traditional Liquid Expressions

### Arithmetic Operators

Arithmetic operators (`+`, `-`, `*`, `/`, `%`) are supported directly in expressions.

Their semantics are consistent with their corresponding filter equivalents. This ensures that:

```
a + b
```

and:

```
a | plus: b
```

behave equivalently.

We also define addition and multiplication operations on arrays and strings.

### Logical Operators and Grouping

Logical operators are supported in standard form:

- `and`
- `or`
- `not`

Parentheses may be used for grouping:

```
not (a and b)
```

Operator precedence is explicit and consistent across all contexts, with short-circuit, last-value semantics.

### A Distinct `Nothing` Value

The language introduces a special `Nothing` value.

`Nothing` represents the absence of a value during evaluation and is distinct from:

- `false`
- `null`
- `nil`

`false`, `null` and implementation-specific `nil` / `undefined` are valid user-data values. `Nothing` is an internal evaluation artifact.

### Coalesce Operator (`??`)

The coalesce operator returns the first operand that is not `Nothing`:

```
a ?? b
```

Unlike `or`, it does not treat `false`, `0`, empty strings, or empty collections as missing values.

### First-Class Filters

Filters are no longer restricted by contextual parsing rules. They participate in the unified expression grammar and can appear anywhere expressions are allowed.

Filters:

- Compose with arithmetic and logical operators
- Respect a single, well-defined precedence hierarchy

The pipe operator (`|`) is treated as a standard expression operator with deterministic behavior.

### First-Class Ternary Expressions

Python-style conditional expressions are supported:

```
value if condition else alternative
```

Ternary expressions are fully composable and follow defined precedence rules. They may be nested and combined with filters, arithmetic, and logical operators.

### Structured Literals and Spread

Array and object literals are supported:

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

### Lambdas (for Filter Arguments)

JavaScript-style arrow functions may be passed as filter arguments:

```
items | map: x => x * 2
```

Lambdas:

- Accept one or more parameters
- Capture lexical scope
- Evaluate a full expression body

Lambdas are higher-order values used exclusively as filter arguments. They are not part of the data model and cannot be returned from filters.

This enables functional-style operations such as mapping, filtering, and aggregation without turning the language into a fully higher-order system.
