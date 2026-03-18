# Introduction

This document is based on [Shopify's Liquid project](https://github.com/Shopify/liquid) and other implementations derived from Shopify's reference implementation.

Historically, Liquid expressions have varied subtly depending on context - certain tags treated operators or filters differently, and precedence rules were not globally consistent.

This document aims to replace ad hoc behavior with a single, composable, context-independent grammar and a clear evaluation model. All operators, filters, and grouping constructs are valid in any expression context, with a single, well-defined precedence hierarchy.

Compatibility with existing Liquid implementations is explicitly not a goal.

## Terminology

- _Template_: TODO":

- _Expression_: An expression is the fundamental unit of computation within a template, representing a sequence of identifiers, literals, and operators that resolves to a value. They appear within output delimiters to render data directly to the page (e.g., `{{ user.name | upcase }}`), inside conditional tags to govern template logic (e.g., `{% if item.price > 100 %}`), and as the data sources for iterations (e.g., `{% for product in collections.frontpage %}`)

  For each of the preceding examples, this tables isolates the expression part of the markup to illustrate some of the places an expression can appear.

  | Markup                                       | Expression              |
  | -------------------------------------------- | ----------------------- |
  | `{{ user.name \| upcase }}`                  | `user.name \| upcase`   |
  | `{% if item.price > 100 %}`                  | `item.price > 100`      |
  | `{% for product in collections.frontpage %}` | `collections.frontpage` |

- _Filter_: TODO:
- _Tag_: TODO:
- _Markup_: TODO:
- _Lambda_: TODO:

## Overview of Liquid Expressions

The Unified Expression Grammar is designed for consistency and reliability, where every syntactically valid expression is guaranteed to produce a result rather than an error.

Every operator, filter, and path resolution is a total function that maps inputs to a defined runtime value. If a conversion or lookup cannot proceed normally, it yields $Nothing$ - a distinct internal state representing the absence of a value, which is then handled deterministically by subsequent operations.

Formally, for every expression $e$ and environment $\rho$:

$$⟦ e ⟧(\rho) \in RuntimeValue$$

TODO: Short overview of expression literals including string interpolation, structured literals and the spread operator

TODO: Short overview of operators, including ternary expressions

TODO: Short overview of filters
