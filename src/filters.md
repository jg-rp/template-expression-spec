### Pipe Operator (Filters)

A filter is a **named total function** registered in the environment. Formally:

$$
\begin{aligned}
FilterFunction \;&: RuntimeValue × List\langle FilterArgument \rangle → RuntimeValue \\
FilterArgument \;&: RuntimeValue | Lambda
\end{aligned}
$$

#### Syntax

```peg
PipeExpression     ← ArithmeticExpression ( S "|" S FilterInvocation )*
FilterInvocation   ← Identifier ( S ":" S ArgumentList )?
ArgumentList       ← Argument ( S "," S Argument )*
Argument           ← LambdaExpression / KeywordArgument / ArgumentExpression
KeywordArgument    ← Identifier S ( "=" / ":" ) S ( LambdaExpression / ArgumentExpression )
LambdaExpression   ← LambdaArguments S "=>" S ArgumentExpression
LambdaArguments    ← Identifier / ( "(" S ( Identifier ( S "," S Identifier )* )? S ")" )
ArgumentExpression ← ArithmeticExpression
```

#### Semantics

Every filter application has at least one argument: the **input**. This is the value resulting from the expression immediately to the left of the pipe. In the conceptual mapping to a standard function, the input always occupies the first positional slot (index 0).

Conceptually, a filter application such as `input | filter: arg1, key=arg2` is evaluated as `filter(input, arg1, key: arg2)`.

The evaluation of a `PipeExpression` follows a linear, left-to-right transformation of data. Each filter in the chain acts as a function that accepts the current result of the pipeline as its first implicit argument.

##### Arguments

Positional arguments are additional values passed to a filter, identified by their sequence following the filter name. The first explicit argument provided in the template is treated as the second argument to the underlying function (index 1), the next as the third (index 2), and so on.

Keyword arguments allow values to be passed to specific named parameters of a filter. Keyword arguments may appear in any order relative to each other, provided they follow all positional arguments. The assignment operators `=` and `:` are treated as semantically identical. They serve only to bind the expression value to the named parameter.

###### Lambda Expressions

Lambda expressions provide a way to define anonymous, inline functions that are passed directly to filters. They allow filters to execute custom logic over collections, such as mapping values, filtering arrays, or applying custom sorting rules.

A lambda expression consists of an argument declaration, an arrow operator (`=>`), and a single expression body.

The left side of the arrow defines the parameters. This can be a single variable name or a parenthesized, comma-separated list of variable names. Parentheses are required if there are zero parameters or multiple parameters.

The right side of the arrow is a single expression that determines the return value of the lambda.

Lambdas act as closures, meaning they capture the lexical environment in which they are defined.

- When evaluated by the filter, the body expression has access to the internal parameters passed into it by the filter.
- The body expression also retains read-access to all variables, and context values that were available in the surrounding template scope at the time the lambda was defined.
- If a lambda parameter shares a name with a variable in the surrounding scope, the lambda parameter strictly shadows the outer variable for the duration of the lambda's execution.

Lambdas are non-first-class.

- They cannot be produced by expression evaluation.
- They cannot be stored in `RuntimeValue`.
- They cannot be returned from filters.
- They can only appear syntactically as filter arguments.

##### Well-Typed Filters

Filter implementations may be accompanied by a **Signature**. This signature is a piece of metadata intended for tooling, static analysis, and ahead-of-time (AOT) validation.

Signatures allow compilers or IDEs to provide autocomplete, verify argument counts, and check for the presence of required keyword arguments before the template is executed. The execution engine MUST NOT depend on this metadata to perform a filter invocation. The engine's role is strictly to evaluate arguments and dispatch the resulting values to the filter implementation.

##### Totality Requirement

All filters MUST be **total functions**. A filter is considered total if it returns a valid value for every possible combination of input and arguments.

- A filter must never throw an exception or halt the execution of the template.
- If a transformation is mathematically or logically impossible (e.g., division by zero, or passing a `String` to a filter that only handles `Numbers` and cannot coerce the value), the filter MUST return `Nothing`.

Filters MUST NOT raise errors due to incorrect arity:

1. **Too Few Arguments** If a required (non-optional, non-variadic) parameter has no corresponding argument, the filter invocation evaluates to `Nothing`.

2. **Too Many Arguments** If extra arguments are supplied and the filter does not declare a variadic parameter, the filter invocation evaluates to `Nothing`.

3. **Variadic Parameters** If a variadic parameter is declared, all remaining arguments are collected into a list and passed as separate positional arguments or as an array, according to the implementation's calling convention.

Filters that are unknown to the environment evaluate to `Nothing`. Implementations MAY throw an error or warning at parse time in the event of an unknown filter.

#### Examples

| Expression                               | Structure           | Notes                                                |
| ---------------------------------------- | ------------------- | ---------------------------------------------------- |
| `val \| upcase`                          | Simple invocation   | No arguments.                                        |
| `val \| round: 2`                        | Positional argument | A single numeric literal argument.                   |
| `val \| replace: "a", "b"`               | Multiple arguments  | Comma-separated positionals.                         |
| `val \| date: format = "%Y"`             | Keyword argument    | Uses `=` for key-value assignment.                   |
| `users \| map: u => u.name`              | Lambda argument     | Single parameter lambda for transformation.          |
| `users \| sort: (a, b) => a.age - b.age` | Multi-arg lambda    | Grouped parameters for comparison logic.             |
| `val \| f: (other \| g)`                 | Nested Pipe         | Parentheses are required to pipe inside an argument. |
