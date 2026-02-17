Once filters are full expression-level postfix operators and filter arguments are full expressions, we must stop thinking of them as “string helpers” and start treating them as **functions inside the evaluation algebra**.

We’ll formalize:

1. What a filter _is_
2. How filter application is evaluated
3. How filter arguments are evaluated
4. How `Nothing` propagates
5. How nested filters like `x | f: (y | g)` behave

---

# 1. Evaluation Domain Recap

We already defined:

```
DataValue =
    Null | Boolean | Number | String | Array | Object

EvalValue =
    DataValue | Nothing
```

Evaluation function:

```
⟦ e ⟧ : Environment → EvalValue
```

Evaluation is total.

---

# 2. What Is a Filter?

A filter is a **named total function** registered in the environment.

Formally:

```
FilterEnv : Identifier → FilterFunction
```

Where:

```
FilterFunction : EvalValue × List<EvalValue> → EvalValue
```

Important:

- Filters are total.
- Filters must not throw.
- Filters may return `Nothing`.
- Filters must not mutate inputs (immutability constraint).

---

# 3. Syntax → Semantic Form

Expression:

```
x | f: a, b, c
```

Desugars semantically to:

```
ApplyFilter(f, x, [a, b, c])
```

Nested case:

```
x | f: (y | g)
```

Desugars to:

```
ApplyFilter(
  f,
  x,
  [ ApplyFilter(g, y, []) ]
)
```

Filter arguments are full expressions.

---

# 4. Evaluation Rule for Pipe

Given:

```
e | f : arg1, arg2, ..., argN
```

Evaluation proceeds in this order:

1. Evaluate base expression
2. If base is `Nothing`, return `Nothing` immediately
3. Evaluate each argument left-to-right
4. If any argument evaluates to `Nothing`, return `Nothing`
5. Call filter function

Formally:

```
⟦ e | f : a1, ..., an ⟧(ρ) =

let v0 = ⟦ e ⟧(ρ)

if v0 = Nothing
    → Nothing

let vi = ⟦ ai ⟧(ρ) for i ∈ [1..n]

if any vi = Nothing
    → Nothing

let F = FilterEnv(f)

return F(v0, [v1..vn])
```

This rule ensures:

- Strict propagation
- Left-to-right determinism
- No partial evaluation leakage

---

# 5. Nested Example Walkthrough

Example:

```
x | f: (y | g)
```

Evaluation:

1. Evaluate `x`
2. If `x = Nothing` → result = Nothing
3. Evaluate `y`
4. If `y = Nothing` → result = Nothing
5. Apply `g(y)`
6. If `g(y) = Nothing` → result = Nothing
7. Apply `f(x, g(y))`

Everything is deterministic.
Everything is total.
No implicit coercion.

---

# 6. Filter Totality Requirement

Each filter must satisfy:

```
∀ v0 ∈ EvalValue, ∀ args ⊆ EvalValue
    F(v0, args) ∈ EvalValue
```

Filters may internally choose to:

- Return `Nothing`
- Return transformed DataValue

But they must never escape the algebra.

---

# 7. Interaction With Coalesce

Given:

```
x | f ?? y
```

Precedence says pipe is lowest, so this parses as:

```
( x | f ) ?? y
```

Evaluation:

1. Evaluate `x | f`
2. If result = Nothing → evaluate `y`
3. Otherwise return result

Clean.
Predictable.
Orthogonal.

---

# 8. Interaction With Boolean

Example:

```
x | f and y
```

Parses as:

```
( x | f ) and y
```

Evaluation:

1. Evaluate `x | f`
2. If result = Nothing → Nothing
3. If result ∉ Boolean → Nothing
4. Otherwise apply Boolean short-circuit

Again: no ambiguity.

---

# 9. Filters as Pure Algebraic Functions

At this point, filters are no longer special syntax.

They are:

```
Named total functions inside the evaluation algebra.
```

Pipe is simply syntactic sugar for function application:

```
x | f:a,b   ≡   f(x, a, b)
```

The only special behavior is:

- Left-to-right evaluation
- Nothing short-circuit before filter invocation

---

# 10. Optional Refinement: Strict vs Lifting Filters

You may later decide to distinguish:

- Strict filters (propagate Nothing)
- Lifting filters (handle Nothing explicitly)

But right now your algebra treats all filters as strict by default.

That’s consistent with the rest of your operator design.

---

# 11. What We’ve Achieved

Your language now has:

- A formally defined value domain
- A bottom element (`Nothing`)
- Total evaluation
- A precedence hierarchy
- Function application via filters
- Nested compositional filter arguments
- Deterministic propagation semantics

This is now a small, well-defined functional expression language embedded in templates.
