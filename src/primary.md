## Primary and Parenthesized Expressions

### Syntax

```peg
PrimaryExpression       ← Variable / Literal / ParenthesizedExpression
ParenthesizedExpression ← "(" S Expression S ")" Path?
```

### Semantics

A $PrimaryExpression$ evaluates to a $RuntimeValue$ as follows:

$Literal$ evaluates to the corresponding literal value (see @sec:literals).

$Variable$ is evaluated via environment lookup and path resolution (see @sec:variables).

$ParenthesizedExpression$ is evaluated by evaluating the inner expression, then applying the optional path (see @sec:variable_resolution).

```
v      = Eval(Expression)
result = ResolvePath(v, Path)
```

If no path is present, the result is simply `v`.

### Examples

Given a context: `{"a": {"c": ["42"]}}`

| Expression    | Evaluation | Notes                                          |
| ------------- | ---------- | ---------------------------------------------- |
| `(2 + 3) * 4` | `20`       | Override operator precedence with parentheses. |
| `(a or b).c`  | `42`       | Path applied on logical expression.            |
