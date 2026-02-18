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

---

---

# 1. Strict vs Lifting (Conceptually)

### Strict operator (what we used before)

```
f(Nothing, …) → Nothing
```

Automatic propagation.
Filter never sees `Nothing`.

---

### Lifting filter (what you want)

```
f : EvalValue × List<EvalValue> → EvalValue
```

And we **do not** pre-check for `Nothing`.

The filter receives `Nothing` as a legitimate input.

This makes `Nothing` part of the public algebra, not a hidden propagation rule.

This is the correct move if:

* `default` must handle `Nothing`
* Some filters treat `Nothing` as empty
* Some filters treat `Nothing` as meaningful

---

# 2. Revised Filter Evaluation Rule

Old rule (strict):

```
If v0 = Nothing → Nothing
If any arg = Nothing → Nothing
Else call F(v0, args)
```

New rule (lifting):

```
⟦ e | f : args ⟧(ρ) =

let v0 = ⟦ e ⟧(ρ)
let vs = [ ⟦ ai ⟧(ρ) ]

return FilterEnv(f)(v0, vs)
```

That’s it.

No automatic `Nothing` propagation.

The filter decides.

This keeps evaluation total and pushes responsibility to the filter definition.

---

# 3. Why This Is Semantically Cleaner

Now:

* `Nothing` is a first-class member of `EvalValue`
* Operators propagate it by rule
* Filters receive it explicitly

This avoids having two propagation systems (operators strict, filters implicit).

Everything is explicit.

---

# 4. Example: `default`

Define:

```
default(v, [fallback]) =
    if v = Nothing
        → fallback
    else
        → v
```

Now:

```
Nothing | default: 5  → 5
Null    | default: 5  → Null
false   | default: 5  → false
0       | default: 5  → 0
```

Exactly what you want.

---

# 5. Optional Arguments

Since filters receive a list:

```
FilterFunction : EvalValue × List<EvalValue> → EvalValue
```

Optional arguments are trivial.

Define:

```
truncate(v, args):
    let length =
        if args has at least 1 element
            → ToNumber(args[0])
        else
            → 30
```

No special typing machinery required.

---

# 6. What About Operators?

Important consistency rule:

Operators remain strict.
Filters are lifting.

This creates a clean distinction:

| Construct  | Behavior with Nothing |
| ---------- | --------------------- |
| Arithmetic | Strict propagation    |
| Boolean    | Strict propagation    |
| Coalesce   | Consumes Nothing      |
| Filters    | Lifting               |

This is elegant and predictable.

---

# 7. Algebraic View

You have now defined:

```
EvalValue = DataValue ∪ {Nothing}
```

Operators are strict functions over this set.
Filters are total functions over this set.

In category-theoretic terms (just conceptually):

* `Nothing` behaves like a bottom element.
* Strict operators are bottom-preserving.
* Filters are arbitrary total functions.

You are not implementing full Maybe-monad lifting.
You’re implementing a controlled bottom algebra.

That’s simpler and more practical.

---

# 8. Important Design Decision

Should filters be *required* to handle `Nothing`, or allowed to treat it as identity?

You likely want this rule in the spec:

> Filters must be total and must explicitly define behavior for `Nothing` inputs.

This prevents accidental reintroduction of partiality.

---

# 9. Edge Case: Nested Example

```
x | f: (y | g)
```

Evaluation:

1. Evaluate `x`
2. Evaluate `y`
3. Apply `g(y)` — even if `y = Nothing`
4. Apply `f(x, result_of_g)`

Nothing is not intercepted unless a filter chooses to.

That’s consistent and powerful.

---

# 10. What You’ve Achieved

Your language now has:

* A formally defined denotational semantics
* A closed evaluation algebra
* Explicit bottom value
* Strict operators
* Lifting filters
* Deterministic evaluation
* Immutability

This is a strong foundation for a formal spec.
