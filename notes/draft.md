# 1. Value Universe

First define the value space.

```
DataValue =
    Null
  | Boolean
  | Number
  | String
  | Array
  | Object
```

Now extend evaluation results:

```
EvalValue =
    DataValue
  | Nothing
```

Important:

- `Nothing ∉ DataValue`
- `Nothing ∈ EvalValue`

This keeps user data separate from evaluation artifacts.

---

# 2. Total Evaluation

Define evaluation function:

```
⟦ e ⟧ : Environment → EvalValue
```

For every expression `e` and environment `ρ`:

```
⟦ e ⟧(ρ) ∈ EvalValue
```

Evaluation never fails.

---

# 3. Name and Path Resolution

### Variable

```
⟦ x ⟧(ρ) =
    if x ∈ dom(ρ)
        ρ(x)
    else
        Nothing
```

### Path Lookup

For `a.b`:

```
let v = ⟦ a ⟧(ρ)

if v ∈ Nothing
    → Nothing
else if v ∈ Object and b ∈ keys(v)
    → v[b]
else
    → Nothing
```

Thus:

- Missing variable → Nothing
- Missing property → Nothing
- Property access on non-object → Nothing

No errors. Total.

---

# 4. Core Propagation Law

This is the backbone:

### Bottom Propagation Rule

For any strict operator `⊗`:

```
If any operand ∈ Nothing
    result = Nothing
```

Unless explicitly overridden (like coalescing).

This ensures:

- Totality
- Deterministic error propagation
- No silent coercion

---

# 5. Conversion Functions

All conversion functions are total:

```
ToNumber : EvalValue → EvalValue
ToString : EvalValue → EvalValue
ToBoolean : EvalValue → EvalValue
```

Rule:

```
ToX(Nothing) → Nothing
```

No conversion ever turns Nothing into a DataValue.

This preserves semantic integrity.

---

# 6. Arithmetic Operators

Example: addition

```
Add : EvalValue × EvalValue → EvalValue
```

Evaluation:

1. If either operand ∈ Nothing → Nothing
2. If both Number → numeric addition
3. If either String → string concatenation
4. If both Array → array concatenation
5. Otherwise → Nothing

This is total.

Invalid combinations produce Nothing, not Null.

---

# 7. Boolean Operators

You have two categories:

### Strict Boolean Operators (`&&`, `||`)

These operate only on Boolean.

Example `&&`:

```
And(a, b):

if a ∈ Nothing → Nothing
if a ∈ Boolean:
    if a == false → false   (short circuit)
    else:
        evaluate b
        if b ∈ Boolean → b
        else → Nothing
else
    → Nothing
```

No truthiness coercion.
Boolean context is explicit.

---

# 8. Nothing-Coalescing Operator

Define abstractly as:

```
Coalesce(a, b):
    if a ∈ Nothing
        evaluate b
    else
        return a
```

Short-circuit.
Total.
Does not propagate Nothing automatically.

This is the only operator that _consumes_ Nothing.

---

# 9. Equality

Define:

```
Nothing == Nothing → true
Nothing == v (v ≠ Nothing) → false
```

No special IEEE-style inequality.
Keep it simple and reflexive.

---

# 10. Conditional Semantics

Define `if` strictly:

```
If(condition):
    let c = ⟦ condition ⟧
    if c ∈ Nothing → Nothing
    if c ∈ Boolean → branch
    else → Nothing
```

No implicit truthiness.
No coercion.
No ambiguity.

---

# 11. Rendering Semantics

Interpolation rule:

```
Render(Nothing) → ""
Render(DataValue) → ToString(DataValue)
```

Nothing disappears in output but remains observable in logic.

---

# 12. Algebraic Structure

You now have:

- A set `EvalValue`
- A distinguished bottom element: `Nothing`
- Strict operators that propagate bottom
- A recovery operator (coalesce)

This is a **flat domain with explicit bottom**, not a lattice of many falsy states.

It satisfies:

- Total evaluation
- Determinism
- Immutability
- Observable semantic failure
- Clean separation of user data vs evaluation artifact

---

# 13. Crucial Property

Nothing can originate from:

- Missing variable
- Missing property
- Invalid operator usage
- Invalid conversion
- Explicit filter return

And it behaves identically regardless of origin.

That uniformity is extremely important.

---

# 14. What We’ve Avoided

You have avoided:

- JavaScript’s `undefined` vs `null` confusion
- NaN’s numeric-only semantics
- Truthiness complexity
- Silent numeric coercion

You now have a principled, specifiable evaluation algebra.
