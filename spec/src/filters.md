# Filters

A filter is a **named total function** registered in the environment.

Formally:

```
FilterEnv : Identifier → FilterFunction
```

Where:

```
FilterFunction : RuntimeValue × List<RuntimeValue> → RuntimeValue
```

The pipe operator `|` represents function application, where the expression on the left is passed as the first argument to the filter on the right.

```
expr | filter1: a, b | filter2: c
```

is equivalent to nested function calls where the previous expression is passed as the first argument to the next filter:

```
filter2(filter1(expr, a, b), c)
```

## Well-Typed Filters

Filters are total functions over `RuntimeValue`. Implementations MAY associate optional type metadata with filter definitions to enable tooling, static diagnostics, or documentation. Such metadata MUST NOT alter runtime semantics.

## Filter Signatures

An implementation MAY register a signature for a filter:

```
FilterSignature =
  parameters: List<ParameterSpec>
  returns: ReturnSpec
```

Where:

```
ParameterSpec =
  hint: ContextHint
  optional: Boolean
  variadic: Boolean
  accepts_lambda: Boolean

ReturnSpec =
  hint: ContextHint
```

- `hint` specifies the coercion context used when preparing the argument.
- `optional` indicates that the argument may be omitted.
- `variadic` indicates that zero or more additional arguments are accepted.
- `accepts_lambda` indicates that the argument position accepts a lambda expression without immediate evaluation.
- `returns.hint` specifies the intended result category for documentation or tooling; it does not affect runtime coercion.

If no signature metadata is provided, all arguments are treated as:

```
hint = default
optional = true
variadic = false
accepts_lambda = false
```

## Argument Evaluation and Coercion

Given:

```
expr | f : a1, a2, ..., an
```

Evaluation proceeds as follows:

1. Evaluate `expr` to `v0`.
2. Evaluate each argument expression `ai` left-to-right to produce `vi`, unless the corresponding parameter is declared `accepts_lambda`, in which case the lambda is passed as a callable value without evaluation.
3. For each parameter with a declared `hint`, coerce the corresponding argument using:

   ```
   vi' = ToLiquid(vi, hint)
   ```

   or the corresponding abstract conversion (`ToNumber`, etc.) as defined by the hint.

4. Invoke the filter function with:

   ```
   f(v0, v1', v2', ..., vk')
   ```

Coercion MUST be total. If coercion for any argument yields `Nothing`, the filter invocation MUST return `Nothing` unless the filter explicitly defines alternate behavior for `Nothing`.

## Arity Mismatch

Filters are total and MUST NOT raise errors due to incorrect arity.

Let:

- `m` be the number of declared parameters (excluding variadic),
- `n` be the number of provided arguments.

Arity handling rules:

1. **Too Few Arguments**
   - If a required (non-optional, non-variadic) parameter has no corresponding argument, the filter invocation evaluates to `Nothing`.

2. **Too Many Arguments**
   - If extra arguments are supplied and the filter does not declare a variadic parameter, the filter invocation evaluates to `Nothing`.

3. **Variadic Parameters**
   - If a variadic parameter is declared, all remaining arguments are collected into a list and passed as separate positional arguments or as an array, according to the implementation’s calling convention.
   - Variadic parameters may accept zero arguments.

Under no circumstances does arity mismatch produce a runtime error.

## Polymorphism

Filters MAY be polymorphic. A filter MAY define behavior for multiple categories of input values.

For example, a filter `length` MAY accept:

- `String`
- `Array`
- `Object`
- `Drop` implementing the `Sequence` protocol

If a filter receives a value outside the categories it supports, it MUST return a defined result. The recommended behavior is to return `Nothing`, though filters MAY instead return another deterministic value (e.g., `0`) if documented.

Polymorphism does not imply static type checking. Any type metadata associated with a filter is advisory and MAY be used for diagnostics, but runtime semantics remain governed solely by the total evaluation rules of this specification.

## Totality Requirement

All filter functions MUST satisfy:

```
FilterFunction : RuntimeValue × List<RuntimeValue> → RuntimeValue
```

For every possible input tuple, a filter MUST return a `RuntimeValue` and MUST NOT raise an exception.

If a filter implementation encounters an internal failure or unsupported input combination, it MUST return `Nothing`.

Filters that are unknown to the environment evaluate to `Nothing`. Implementations MAY throw an error or warning at parse time in the even of an unknown filter.

## Lambda Expressions

Lambda expressions provide a way to define anonymous, inline functions that are passed directly to filters. They allow filters to execute custom logic over collections, such as mapping values, filtering arrays, or applying custom sorting rules.

**Structure**

A lambda expression consists of an argument declaration, an arrow operator (`=>`), and a single expression body.

- **Arguments:** The left side of the arrow defines the parameters. This can be a single variable name or a parenthesized, comma-separated list of variable names. Parentheses are required if there are zero parameters or multiple parameters.

- **Body:** The right side of the arrow is a single expression that determines the return value of the lambda.

- **Placement:** Lambdas can be passed to filters as standard positional arguments or assigned as the value of a keyword argument.

**Evaluation and Invocation**

Unlike standard filter arguments, a lambda expression is not evaluated immediately when the template engine processes the filter chain.

- If a filter's signature declares a parameter with the `accepts_lambda` flag set to true, the lambda is passed to the filter as an opaque, callable `RuntimeValue`.
- The receiving filter is responsible for invoking the lambda, providing the necessary arguments during the invocation (for example, passing each item of an array to the lambda one by one).
- If a lambda is passed to a filter parameter that does not explicitly accept lambdas, the evaluation MUST yield `Nothing`.

**Scope and Capture**

Lambdas act as closures, meaning they capture the lexical environment in which they are defined.

- When evaluated by the filter, the body expression has access to the internal parameters passed into it by the filter.
- The body expression also retains read-access to all variables, drops, and context values that were available in the surrounding template scope at the time the lambda was defined.
- If a lambda parameter shares a name with a variable in the surrounding scope, the lambda parameter strictly shadows the outer variable for the duration of the lambda's execution.
