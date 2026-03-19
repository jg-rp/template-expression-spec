# Introduction

This specification defines the behavior of a standalone expression evaluator. In practice, this evaluator is intended to function as a component within a larger template engine.

While the template engine manages higher-level concerns - such as file I/O, tag orchestration (`{% ... %}`), and the provision of a global execution context - this document governs the internal logic of **Expressions**. By decoupling the expression grammar from the engine's tag architecture, we ensure that data resolution, mathematical operations, and filter pipelines remain consistent regardless of the tag or context in which they appear.

## Terminology

- _Template_: The source document or string containing a mix of static text (to be rendered literally) and dynamic **Markup**. It serves as the primary unit of execution for the engine.

- _Template Engine_: The software system that orchestrates the transformation of a **Template** into a rendered output. It is responsible for parsing the surrounding **Markup**, managing the execution context (environment), and invoking the expression evaluator to resolve **Expressions**, **Filters**, and **Lambdas** as defined in this specification. While the engine handles high-level concerns like file loading and **Tag** execution, it relies on the Unified Expression Grammar for all data resolution and computation.

- _Expression_: An expression is the fundamental unit of computation within a template, representing a sequence of identifiers, literals, and operators that resolves to a value. They appear within output delimiters to render data directly to the page (e.g., `{{ user.name | upcase }}`), inside conditional tags to govern template logic (e.g., `{% if item.price > 100 %}`), and as the data sources for iterations (e.g., `{% for product in collections.frontpage %}`)

  For each of the preceding examples, this tables isolates the expression part of the markup to illustrate some of the places an expression can appear.

  | Markup                                       | Expression              |
  | -------------------------------------------- | ----------------------- |
  | `{{ user.name \| upcase }}`                  | `user.name \| upcase`   |
  | `{% if item.price > 100 %}`                  | `item.price > 100`      |
  | `{% for product in collections.frontpage %}` | `collections.frontpage` |

- _Markup_: The collective term for the specialized syntax (delimited by `{{` and `{%`) embedded within a template. Markup distinguishes dynamic instructions - such as output statements and tags - from static content.

- _Tag_: A structural command used to govern control flow, iteration, or state management (e.g., `if`, `for`, `assign`). While this specification defines the grammar of expressions _within_ tags, the implementation of the tags themselves is considered part of the surrounding architecture.:

- _Filter_: A named, total function registered in the environment that transforms a value. Filters are invoked within a pipeline using the pipe (`|`) syntax, where they accept the result of the preceding expression as their primary input.

- _Lambda_: An anonymous function defined inline as a filter argument. Lambdas capture their lexical environment and allow filters to apply custom logic such as mapping or sorting to data structures.

- _Total Evaluation_: An expression language has total evaluation if every syntactically valid expression evaluates to a value and does not raise a runtime error. Every operator, filter, and conversion must produce a value for every possible input.

- _Total Function_: A function is total if it is defined for every possible input in its domain - the set of inputs the function accepts.

## History

This specification is based on [Shopify's Liquid project](https://github.com/Shopify/liquid) and other implementations derived from Shopify's reference implementation.

Historically, Liquid expressions have varied subtly depending on context - certain tags treated operators or filters differently, and precedence rules were not globally consistent.

This document aims to replace ad hoc behavior with a single, composable, context-independent grammar and a clear evaluation model. All operators, filters, and grouping constructs are valid in any expression context, with a single, well-defined precedence hierarchy.

Compatibility with existing Liquid implementations is explicitly not a goal.

## Overview of Liquid Expressions

An expression is a composable sequence of components that, when evaluated against a context, produces a single $RuntimeValue$. This language is total and immutable: every syntactically valid expression resolves to a value, and no expression can modify the state of the execution context.

Formally, for every expression $e$ and environment $\rho$:

$$⟦ e ⟧(\rho) \in RuntimeValue$$

Expressions are composed of the following six building blocks:

### Literals

Literals are textual representations of fixed values encoded directly in the template source, including:

- Primitives: `Strings` (UTF-8), `Numbers` (High-precision decimals), `Booleans` (`true`/`false`), and `Null`.
- Collections: `Array` literals (`[1, 2, 3]`) and `Object` literals (`{ key: value }`).
- Ranges: `Range` literals (`1..5`) which evaluate to an inclusive sequence of integers.

### Variables and Paths

Variables are identifiers used to retrieve data from the execution context. They support deep resolution via segmented path syntax:

- Dot Notation: `user.profile.name`
- Bracket Notation: `user["profile"]["name"]` or `items[index]`.
  If a variable or any segment of a path does not exist, the expression resolves to $Nothing$.

### Operators

Operators perform functional computations or logical comparisons.

- Arithmetic: Standard mathematical operations (`+`, `-`, `*`, `/`, `%`) and unary negation (`-`).
- Comparison: Equality (`==`, `!=`) and relational (`<`, `<=`, `>`, `>=`) checks.
- Logical: Boolean logic (`and`, `or`, `not`) used for truthiness branching.
- Coalescence: The `orElse` operator provides a fallback specifically for $Nothing$ values.
- Membership: The `in` and `contains` operators for checking if a value exists within a collection or a substring exists within a string.

### Filters and Pipelines

Filters are named transformations applied to a value via the pipe (`|`) syntax. They are designed to be chained into pipelines, where the output of one filter serves as the primary input for the next (e.g., `product.price | times: 1.1 | round: 2`). Filters may accept:

- Positional Arguments: `filter: arg1, arg2`
- Keyword Arguments: `filter: key="value"`

### Lambdas

Lambdas are anonymous, inline functions (e.g., `item => item.price > 10`) passed as arguments to filters. They allow filters to delegate logic back to the expression engine, enabling powerful operations like custom sorting, mapping, and searching within collections while maintaining lexical scope.

### Control Expressions

- Conditional (Ternary): The `... if ... else ...` construct allows for inline branching based on the truthiness of a condition (e.g., `score if score > 50 else "Fail"`).
- Grouping: Parentheses `( ... )` are used to override default operator precedence or to clarify the evaluation order of complex nested expressions.
