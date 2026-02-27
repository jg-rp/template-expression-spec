Now we’re at the part where template languages either become elegant… or slowly accumulate ghosts.

You’ve already done something very strong:

```
DataValue =
    Null | Boolean | Number | String | Array | Object

EvalValue =
    DataValue | Nothing
```

That’s a **closed semantic core**.

Now you want to introduce:

> Developer-defined types (“Drops”) that can be coerced into an `EvalValue`, possibly with a context hint (numeric context, string context, etc.)

This is a powerful extension — but it touches the closure property of your algebra.

Let’s break this down cleanly.

---

# 1. What Is a Drop Semantically?

A Drop is not a value in your core universe.

It is:

> An external object that can be interpreted as a value.

Formally, you are introducing something like:

```
HostValue   // implementation-defined
Drop ⊆ HostValue
```

And a coercion function:

```
coerce : Drop × ContextHint → EvalValue
```

That’s not just a type addition — that’s a _semantic boundary crossing_.

You now have two worlds:

- The **language value space**
- The **host runtime world**

That boundary must stay very clearly defined.

---

# 2. How to Describe Drops in English

Here is a clean formulation:

> In addition to the core value space, the implementation may expose developer-defined objects known as Drops. A Drop is not itself a data value in the language. Instead, it is an object that can be coerced into an evaluation value when required, possibly using a context hint such as numeric or string context.

That keeps your formal model intact.

Drops are not values.
They are _interpretable objects_.

That distinction matters enormously.

---

# 3. Should Filters Be Allowed to Return Drops?

This is the real design fork.

Let’s examine both options.

---

## Option A — Filters May Return Drops

Then your evaluation function becomes:

```
eval : Expression → EvalValue | Drop
```

Which means:

- Your language is no longer closed.
- Any operator might now receive a Drop.
- Coercion rules must apply everywhere.

This spreads host semantics across the entire evaluator.

You lose the clean boundary.

You also introduce subtle questions:

- Does equality compare Drop identity?
- Is Drop truthy before coercion?
- Does `??` coerce before testing null?
- Does `+` coerce both operands?

Your algebra becomes “value + implicit interpretation layer”.

This is how many template engines become unpredictable.

---

## Option B — Filters Must Return EvalValue

This preserves closure:

```
eval : Expression → EvalValue
```

Drops may appear:

- As inputs (via variable resolution)
- But must be coerced before being returned from evaluation steps

This keeps your core language algebra closed.

That’s a huge architectural advantage.

---

# 4. The Cleanest Semantic Model

The most principled approach is:

### Value Space (Closed Core)

```
DataValue
EvalValue = DataValue | Nothing
```

### Host Extension Layer

```
HostValue =
    EvalValue
  | Drop
```

### Coercion Rule

Whenever evaluation requires a `DataValue`, if the operand is a Drop:

```
coerce(drop, context) → EvalValue
```

But evaluation _never returns_ Drop.

That preserves closure while allowing extensibility.

---

# 5. About Context Hints

Contextual coercion (numeric vs string) is powerful but dangerous.

You are effectively introducing multi-method coercion:

```
to_number(drop)
to_string(drop)
to_boolean(drop)
```

That’s fine — as long as:

- It is explicit in operator semantics
- It is deterministic
- It does not depend on global state

In English:

> A Drop may define context-sensitive conversions that determine how it behaves in numeric, string, or boolean contexts.

That’s a standard and defensible model.

---

# 6. Why Allowing Filters to Return Drops Is Risky

If filters can return Drops, then Drops become part of intermediate expression evaluation.

That means:

- You must define operator behavior for Drop operands.
- You must define propagation rules.
- You lose the guarantee that expressions evaluate to a closed value universe.

In algebraic terms:

Your language stops being closed over `EvalValue`.

Instead, it becomes:

```
Expression → HostValue
```

That’s a fundamentally weaker semantic property.

---

# 7. My Strong Recommendation

Do **not** allow filters to return Drop.

Instead:

- Drops may appear only via variable resolution.
- Drops must be coerced when entering the expression algebra.
- Evaluation always returns `EvalValue`.

This gives you:

- Closure
- Predictability
- Simpler reasoning
- Cleaner documentation
- Easier testing
- Stronger long-term correctness

You can still allow filters to accept Drop as input — as long as they coerce before returning.

---

# 8. How to Describe This Cleanly in Documentation

Here’s a precise but readable version:

> The core expression language is closed over a fixed universe of evaluation values. Implementations may expose developer-defined objects called Drops. Drops are not themselves evaluation values, but may be coerced into one when required by the evaluation rules, optionally using a context hint such as numeric or string context. Evaluation of expressions always produces an evaluation value; Drops do not appear as final results.

That preserves both flexibility and formal integrity.

---

# 9. The Deeper Principle

You’re at a crossroads between:

- A mathematically coherent expression language with a clean semantic core
- A dynamically permeable template runtime where host objects leak into evaluation

The first scales better.

Given everything you've built so far — I strongly suspect you prefer the first.

---

If you'd like, we can next examine:

- Whether `Nothing` should propagate like bottom (⊥)
- Whether Drops should be memoized post-coercion
- Or how to formalize coercion in your evaluation algebra cleanly

This is now real language design territory.
