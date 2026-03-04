## Range Literals

A range literal denotes a finite sequence of consecutive integers.

Syntactic form:

```
range_literal ::= start ".." end
```

Where:

- `start` and `end` are arbitrary expressions.
- The `..` operator binds at the same precedence level as other primary expressions.
- Parentheses MAY be used for grouping.

Examples:

```
1..5
(1 + 1)..10
a..b
```

---

## Evaluation Semantics

A range literal is syntactic sugar. It evaluates as follows:

1. Evaluate `start` to `v_start`.
2. Evaluate `end` to `v_end`.
3. Apply numeric coercion:

```
n_start = ToNumber(v_start)
n_end   = ToNumber(v_end)
```

4. If either coercion yields `Nothing`, the range expression evaluates to `Nothing`.

5. Otherwise:
   - Both numbers are converted to integers using implementation-defined truncation toward zero.
   - The result is the sequence of all integers `n` such that:

```
n_start ≤ n ≤ n_end
```

If `n_start > n_end`, the result is an empty sequence.

---

## Result Type

The result of a range literal is one of:

- `Array<RuntimeValue>` containing integer values
- A `Drop` implementing the `Sequence` protocol that yields integer values

Implementations MAY choose either representation.

### Requirements

If implemented as:

#### 1. Eager Array

The result MUST be:

```
[ n_start, n_start + 1, ..., n_end ]
```

Each element is an integer `Number`.

#### 2. Lazy Sequence Drop

The result MUST be a `Drop` implementing the `Sequence` protocol:

```
length()  → max(0, n_end - n_start + 1)
iterate() → yields each integer in order
slice()   → returns another range-like Drop
```

The observable semantics MUST be indistinguishable from the eager array for all language operations.

---

## Interaction with `for`

Range literals are valid iterable expressions.

For:

```
{% for i in 1..5 %}
```

Evaluation is equivalent to:

```
ToArray(1..5)
```

If the range evaluates to `Nothing`, `ToArray(Nothing)` produces `[]`, and the loop executes zero times.

---

## Interaction with Filters and Operators

Because range literals evaluate to a `RuntimeValue`, they:

- May be piped into filters.
- May participate in comparisons.
- May be passed to membership operators.
- May be used inside larger arithmetic expressions.

Example:

```
(1..5) | length
3 in (1..5)
(1..5) == [1,2,3,4,5]
```

All such expressions MUST behave identically whether the implementation chooses eager or lazy representation.

---

## Determinism and Totality

Range literals are total.

A range expression evaluates to:

- `Nothing` if either bound cannot be coerced to a number.
- A finite sequence otherwise.

Range literals MUST NOT raise errors due to:

- Non-numeric bounds
- Extremely large bounds (implementations MAY impose practical limits but MUST degrade deterministically, e.g., returning `Nothing`).

---

## Design Notes

Range literals are defined as syntactic sugar rather than a primitive type to preserve:

- Uniform `RuntimeValue` semantics
- Compatibility with `Array` and `Sequence` protocols
- Implementation flexibility (eager vs lazy)
- Total evaluation guarantees

The language does not define descending ranges. Authors requiring reverse iteration SHOULD apply a sequence-aware filter such as `reverse`.

---

# Optional Refinement (If You Want It)

You may optionally define whether bounds are evaluated:

- Once at range creation (recommended)
- Lazily at iteration time (more complex but possible for Drop-based implementations)

The simpler rule — and more consistent with your evaluation model — is:

> Bounds are evaluated immediately when the range literal is evaluated.

---

If you'd like, we can now examine a subtle edge case:

Should `1.2..3.8` produce `[1,2,3]`, `[2,3]`, or be `Nothing`?

Right now the draft specifies truncation toward zero — but that choice affects determinism and cross-implementation consistency.
