# Introduction

This document is based on Shopify's [Liquid](https://github.com/Shopify/liquid) project and other implementations derived from Shopify's reference implementation.

Historically, Liquid expressions have varied subtly depending on context - certain tags treated operators or filters differently, and precedence rules were not globally consistent.

This document aims to replace ad hoc behavior with a single, context-independent grammar and a clear evaluation model. All operators, filters, and grouping constructs are valid in any expression context, with a single, well-defined precedence hierarchy.

## Terminology

- _Expression_: An expression is the fundamental unit of computation within a Liquid template, representing a sequence of identifiers, literals, and operators that resolves to a value. They appear within output delimiters to render data directly to the page (e.g., `{{ user.name | upcase }}`), inside conditional tags to govern template logic (e.g., `{% if item.price > 100 %}`), and as the data sources for iterations (e.g., `{% for product in collections.frontpage %}`)

  For each of the preceding examples, this tables isolates the expression part of the markup to illustrate some of the places an expression can appear.

  | Markup                                       | Expression              |
  | -------------------------------------------- | ----------------------- |
  | `{{ user.name \| upcase }}`                  | `user.name \| upcase`   |
  | `{% if item.price > 100 %}`                  | `item.price > 100`      |
  | `{% for product in collections.frontpage %}` | `collections.frontpage` |

- _Filter_: TODO:
- _Markup_: TODO:
- _Lambda_: TODO:

## Overview of Liquid Expressions

The Unified Expression Grammar is designed for consistency and reliability, where every syntactically valid expression is guaranteed to produce a result rather than an error.

Every operator, filter, and path resolution is a total function that maps inputs to a defined runtime value. If a conversion or lookup cannot proceed normally, it yields $Nothing$ - a distinct internal state representing the absence of a value, which is then handled deterministically by subsequent operations.

Formally, for every expression $e$ and environment $\rho$:

$$⟦ e ⟧(\rho) \in RuntimeValue$$

### Literals

TODO: String interpolation

TODO: Structured Literals and Spread

### Operators

TODO:

### Filters

Filters are first-class citizens integrated into the recursive structure of the grammar. They can be nested within parentheses, allowing the output of a pipeline to be used as an operand in arithmetic or comparison.

```
(x | upper) == 'FOO'
```

TODO: lambda arguments

### Ternary Expressions

TODO:

### Extension Types (Drops)

Drops participate in the language's semantics through structured protocols:

- **Context-Aware Coercion**: Drops use `ToLiquid` with context hints (numeric, string, boolean, etc.) to provide the most appropriate value for the current operation.
- **Behavioral Protocols**: Implementations can opt into specific protocols - **Sequence**, **Equality**, **Ordering**, and **Membership** - allowing developer-defined objects to behave like native arrays or comparable primitives without losing their internal complexity.
