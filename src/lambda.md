## Lambda Expressions {#sec:lambda}

### Syntax

A lambda expression consists of an argument declaration, an arrow operator (`=>`), and a single expression body.

The left side of the arrow defines the parameters. This can be a single variable name or a parenthesized, comma-separated list of variable names. Parentheses are required if there are zero parameters or multiple parameters.

The right side of the arrow is a single expression that determines the return value of the lambda.

```peg
LambdaExpression        ← LambdaParameters S ( "=>" / "->" ) S Expression
LambdaParameters        ← Identifier / ( "(" S ( Identifier ( S "," S Identifier )* )? S ")" )
```

### Semantics

Lambdas are stateless, meaning they do not capture the lexical environment in which they are defined.

TODO: via drop protocol

### Examples

TODO
