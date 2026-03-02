This overview for `spec.md` outlines the design philosophy and technical pillars of the language, emphasizing its departure from traditional Liquid constraints in favor of a more robust, deterministic model.

---

## Overview

The Unified Expression Grammar is designed for predictability, reliability, and expressive power. While it takes functional cues from Liquid, it is a distinct dialect optimized for a **total evaluation model** where every syntactically valid expression is guaranteed to produce a result rather than an error.

### Philosophy and Approach

The core tenet of this language is **Total Evaluation**: evaluation never fails. In many template engines, a missing variable or a type mismatch results in a runtime crash or an unhandled exception. Here, every operator, filter, and path resolution is a total function that maps inputs to a defined `RuntimeValue`. If a conversion or lookup cannot proceed normally, it yields `Nothing`—a distinct internal state representing the absence of a value, which is then handled deterministically by subsequent operations.

Formally, for every expression $e$ and environment $\rho$:

$$⟦ e ⟧(\rho) \in RuntimeValue$$

This ensures that the rendering process is stable and safe, regardless of the quality of the input data.

### First-Class Filters

In this grammar, filters are more than just post-processing helpers; they are **first-class citizens**. Because filters are integrated into the recursive structure of the grammar, they can appear almost anywhere an expression is expected.

- **Recursive Composition**: Filters can be nested within parentheses, allowing the output of a pipeline to be used as an operand in arithmetic or comparison.
- **High-Order Arguments**: Filters can accept **lambdas** as arguments, enabling functional patterns like mapping, filtering, and reducing directly within the template.

### Extensibility via Drop Protocols

To bridge the gap between host-language objects and the template environment, the specification introduces **Drops**. Unlike simple "dumb" objects, Drops participate in the language's semantics through structured protocols:

- **Context-Aware Coercion**: Drops use `ToLiquid` with context hints (numeric, string, boolean, etc.) to provide the most appropriate value for the current operation.
- **Behavioral Protocols**: Implementations can opt into specific protocols—**Sequence**, **Equality**, **Ordering**, and **Membership**—allowing developer-defined objects to behave like native arrays or comparable primitives without losing their internal complexity.

### A Note on Compatibility

**Compatibility with existing Liquid implementations is explicitly not a goal.** While the syntax will feel familiar to Liquid users, this specification prioritizes mathematical consistency and modern features (such as null-coalescing, spread operators, and predicates) over bug-for-bug parity with Ruby-based or Shopify-flavored Liquid. This allows the language to adopt structural truthiness and more intuitive operator precedence without being hindered by legacy constraints.

---
