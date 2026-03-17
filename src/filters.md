## Filters

A filter is a **named total function** registered in the environment.

Formally:

```
FilterEnv : Identifier → FilterFunction
```

Where:

```
FilterFunction : RuntimeValue × List<RuntimeValue> → RuntimeValue
```

Filters are transformations applied to a value via the pipe operator (`|`). While they are written linearly, they are semantically equivalent to nested function calls where the value to the left of the pipe is passed as the first argument.

### The Input Value

Every filter application has at least one argument: the **input**. This is the value resulting from the expression immediately to the left of the pipe. In the conceptual mapping to a standard function, the input always occupies the first positional slot (index 0).

### Positional Arguments

Positional arguments are additional values passed to a filter, identified by their sequence following the filter name.

- **Ordering:** The first explicit argument provided in the template is treated as the second argument to the underlying function (index 1), the next as the third (index 2), and so on.
- **Separators:** Arguments are separated by commas. While some implementations may allow whitespace as a delimiter for backward compatibility, commas are the canonical separator.
- **Placement:** All positional arguments MUST appear before any keyword arguments.

### Keyword Arguments

Keyword arguments allow values to be passed to specific named parameters of a filter. This enhances readability for filters with multiple optional configuration flags.

- **Structure:** A keyword argument consists of a name (identifier), followed by an assignment operator (`=` or `:`), and an expression.
- **Semantic Equivalence:** The assignment operators `=` and `:` are treated as semantically identical. They serve only to bind the expression value to the named parameter.
- **Ordering:** Keyword arguments may appear in any order relative to each other, provided they follow all positional arguments.
- **Uniqueness:** A specific keyword name may only be used once within a single filter application.

### Evaluation Model

1. **Left-to-Right:** The input expression and all arguments (both positional and keyword) are evaluated in the order they appear in the source text.
2. **Total Evaluation:** Every argument expression must be successfully evaluated to a value (which may be `Nothing`) before the filter itself is invoked.
3. **Conceptual Mapping:** A filter application such as `input | filter: arg1, key=arg2` is conceptually evaluated as `filter(input, arg1, key: arg2)`.

### Well-Typed Filters

While filters are invoked dynamically, they may be accompanied by a **Signature**. This signature is a piece of metadata intended for tooling, static analysis, and ahead-of-time (AOT) validation.

- **Parse-Time Utility:** Signatures allow compilers or IDEs to provide autocomplete, verify argument counts, and check for the presence of required keyword arguments before the template is executed.
- **Decoupling:** The execution engine MUST NOT depend on this metadata to perform a filter invocation. The engine's role is strictly to evaluate arguments and dispatch the resulting values to the filter implementation.
- **Polymorphism:** Because signatures are for tooling, a single filter name may be associated with multiple signatures (overloading) or a variadic signature without affecting the runtime evaluation model.

### Argument Evaluation and Coercion

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

### Arity Mismatch

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

### Totality Requirement

All filters MUST be **total functions**. A filter is considered total if it returns a valid value for every possible combination of input and arguments.

- **No Exceptions:** A filter must never throw an exception or halt the execution of the template.
- **Fallback to Nothing:** If a transformation is mathematically or logically impossible (e.g., division by zero, or passing a `String` to a filter that only handles `Numbers` and cannot coerce the value), the filter MUST return `Nothing`.
- **Consistency:** The return value of a failed filter application should be indistinguishable from a variable lookup that yielded no result, allowing the `??` (Null Coalescing) operator to handle the fallback gracefully.

Formally, for every possible input tuple, a filter MUST return a `RuntimeValue` and MUST NOT raise an exception.

```
FilterFunction : RuntimeValue × List<RuntimeValue> → RuntimeValue
```

If a filter implementation encounters an internal failure or unsupported input combination, it MUST return `Nothing`.

Filters that are unknown to the environment evaluate to `Nothing`. Implementations MAY throw an error or warning at parse time in the even of an unknown filter.

### Lambda Expressions

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
