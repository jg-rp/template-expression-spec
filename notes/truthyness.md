# 1. Truthiness as a Total Function

We define a total function:

```
truthy : EvalValue → Boolean
```

Truthiness is used to interpret expressions in conditional contexts (e.g., `if`, `and`, `or`).

---

# 2. Definition Over `EvalValue`

Recall:

```
EvalValue =
    DataValue
  | Nothing
```

and

```
DataValue =
    Null
  | Boolean
  | Number
  | String
  | Array
  | Object
```

We define `truthy` by structural case analysis.

---

# 3. Formal Definition

```
truthy(Nothing)           = false

truthy(Null)              = false

truthy(Boolean(false))    = false
truthy(Boolean(true))     = true

truthy(Number(n))         = (n ≠ 0)

truthy(String(s))         = (length(s) > 0)

truthy(Array(a))          = (length(a) > 0)

truthy(Object(o))         = (size(o) > 0)
```

This definition is:

- Total
- Deterministic
- Structural
- Independent of host language semantics

---

# 4. Structural Characterization

Truthiness can be summarized as:

> An evaluation result is truthy iff it represents a non-empty, non-zero, non-null value.

Or more abstractly:

> `truthy(v)` is false exactly when `v` represents absence, nullity, falsity, or structural emptiness.

---

# 5. Relationship to `Nothing`

Important distinction:

- `Nothing` represents absence of evaluation result.
- `Null` represents explicit data.

Both are falsy, but remain semantically distinct.

This ensures:

```
defined?(Nothing) = false
defined?(Null)    = true
```

even though:

```
truthy(Nothing) = false
truthy(Null)    = false
```

Truthiness does not collapse semantic categories.

---

# 6. Conditional Semantics

Conditional constructs use `truthy`:

```
⟦if e then a else b⟧ =
    if truthy(⟦e⟧)
        then ⟦a⟧
        else ⟦b⟧
```

Short-circuit operators are defined similarly:

```
⟦e1 and e2⟧ =
    let v1 = ⟦e1⟧ in
        if truthy(v1)
            then ⟦e2⟧
            else v1

⟦e1 or e2⟧ =
    let v1 = ⟦e1⟧ in
        if truthy(v1)
            then v1
            else ⟦e2⟧
```

Note:

- `and` and `or` return `EvalValue`, not Boolean.
- This preserves expression composability.
- `Nothing` propagates naturally through falsiness.

---

# 7. Design Rationale (Documentation-Friendly)

You might include a short rationale paragraph:

> The language adopts structural truthiness. Empty strings, empty arrays, empty objects, zero numbers, null, and absence (`Nothing`) are falsy. All other values are truthy. This rule is uniform across value types and does not depend on host-language semantics.

---

# 8. Optional: Compact Mathematical Definition

If you prefer a more abstract formulation:

Let:

```
isEmpty(v) :=
    v = String(s)  ∧ length(s) = 0
 ∨  v = Array(a)   ∧ length(a) = 0
 ∨  v = Object(o)  ∧ size(o) = 0
```

Then:

```
truthy(v) =
    false  if v ∈ { Nothing, Null, Boolean(false) }
    false  if v = Number(0)
    false  if isEmpty(v)
    true   otherwise
```

---

# 9. Why This Fits Your System

This definition:

- Respects your closed value universe
- Is fully total
- Requires no sentinel values
- Makes `blank?` and `empty?` descriptive rather than required for control flow
- Eliminates legacy Ruby quirks
- Is intuitive for template authors

It is also algebraically clean: truthiness is derived from structure, not historical convention.

---
