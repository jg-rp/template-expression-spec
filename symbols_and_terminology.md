# 1. What Is a _Total Function_?

In mathematics, a function is **total** if it is defined for every possible input in its domain.

Formally:

> A function `f : A → B` is _total_ if for every `a ∈ A`, there exists a well-defined value `f(a) ∈ B`.

There are no inputs for which the function is “undefined”.

By contrast, a **partial function** is one that is not defined for some inputs.

Example of a partial function:

```
sqrt(x)
```

Over real numbers, this is undefined for negative `x`. It is not total unless you expand the number system or define fallback behavior.

---

# 2. What Is _Total Evaluation_?

In programming language terms:

> An expression language has **total evaluation** if every syntactically valid expression evaluates to a value and does not raise a runtime error.

This means:

- No type errors at runtime.
- No “method not found”.
- No “invalid operand types”.
- No exceptions during evaluation.

Every operator, filter, and conversion must produce a value for every possible input.

In a templating context (like Liquid), total evaluation ensures:

- Rendering never crashes.
- A page always renders something.
- Failures degrade predictably.

---

# 3. What Are _Fully Total Conversion Functions_?

When we defined:

```
ToNumber : Value → Number
ToString : Value → String
ToArray  : Value → Array
ToBoolean: Value → Boolean
```

We said they were _fully total_.

That means:

1. They accept every member of `Value`.
2. They never throw.
3. They always return a value in their codomain.
4. Their behavior is deterministic.

For example:

```
ToNumber("abc") → 0
```

Instead of:

- Throwing a parse error
- Returning “undefined”
- Crashing rendering

The function defines fallback behavior.

The word “fully” here emphasizes that:

- There are no edge cases left unspecified.
- The function is defined across the entire value space.
- There is no implicit partiality hiding in parsing rules.

---

# 4. What Is the _Totality Rule_?

The **totality rule** is a design constraint for the language:

> Every operator and filter must be implemented as a total function over `Value`.

Formally:

If `⊕` is a binary operator:

```
⊕ : Value × Value → Value
```

Then:

For all `a ∈ Value` and `b ∈ Value`,
`a ⊕ b` must return a `Value`.

There must be no operand pair for which evaluation fails.

In narrative terms:

- The language does not reject type combinations at runtime.
- It resolves them according to documented coercion rules.
- If no meaningful semantic exists, it returns a defined fallback (often `Null`).

---

# 5. Why This Matters for a Template Language

In a general-purpose language, partiality is acceptable:

- Type errors are surfaced to developers.
- Exceptions are part of control flow.

But in a template system:

- Authors are not necessarily programmers.
- Templates run in production.
- Rendering failure is unacceptable.

So the language must prefer:

- Defined fallback behavior
- Deterministic coercion
- Stability over strictness

Total evaluation is a deliberate tradeoff:
You sacrifice strict type safety to guarantee render stability.

---

# 6. What Totality Does _Not_ Mean

Total does **not** mean:

- “Everything coerces to everything”.
- “There is no type system”.
- “All combinations produce intuitive results”.

It means:

- Every combination produces a documented result.

The predictability comes from the spec, not from intuition.

---

# 7. How This Shapes `+`

When we defined:

```
Add : Value × Value → Value
```

We were asserting totality.

Even for:

```
Object + Object
```

We must define behavior (e.g., numeric fallback or Null).

If we fail to define it, `+` becomes partial.

Partial operators violate total evaluation.

---

# 8. The Narrative Summary

In your redesigned Liquid:

- The value domain is closed and finite.
- Conversion functions are total.
- Operators are total.
- Filters are total.
- Evaluation never throws.

The system guarantees:

> Every valid template renders to a value, regardless of data shape.

That is what “total evaluation” means in this context.

---

Excellent — this is exactly the right move. If we’re going to write spec-level definitions, the mathematical vocabulary needs to be clear and grounded in this context.

I’ll define each term plainly, then connect it directly to your Liquid redesign.

---

# 1. Domain

When we write:

```
ToNumber : Value → Number
```

the **domain** is the set of inputs the function accepts.

More formally:

> The domain of a function is the set of all values for which the function is defined.

In your language:

- If we define

  ```
  ToNumber : Value → Number
  ```

  then the domain is the entire `Value` type.

That means:

- Null is in the domain.
- Boolean is in the domain.
- String is in the domain.
- Array is in the domain.
- Object is in the domain.

Because the function is total, every one of those inputs must produce a result.

If instead we defined:

```
sqrt : Number → Number
```

then the domain would be `Number`, not `Value`.

---

# 2. Codomain

The **codomain** is the set of possible outputs the function promises to return.

In:

```
ToNumber : Value → Number
```

- The domain is `Value`
- The codomain is `Number`

This means:

- For every input in `Value`, the function returns something in `Number`.
- It will never return a String.
- It will never return an Array.

Important distinction:

The codomain is what the function _claims_ it returns.
The actual results are a subset of the codomain.

For example:

```
ToBoolean : Value → Boolean
```

The codomain is `{true, false}`.

---

# 3. Member

When we write:

```
a ∈ Value
```

we mean:

> `a` is a member (an element) of the set `Value`.

So if:

```
Value =
  Null | Boolean | Integer | Float | String | Array | Object
```

then:

```
5 ∈ Value
"hi" ∈ Value
null ∈ Value
[1,2] ∈ Value
```

But:

```
function() {} ∉ Value
```

(because functions are not part of your value domain)

So “member” just means:

> One specific value belonging to a defined set of values.

---

# 4. Meaning of the Symbols

Let’s translate each symbol into plain English.

---

## `→`

This means:

> “Maps to”
> “Is a function from … to …”

Example:

```
ToString : Value → String
```

Reads as:

> ToString is a function that takes a Value and returns a String.

---

## `∈`

This means:

> “Is a member of”
> “Belongs to”

Example:

```
a ∈ Value
```

Reads as:

> a is a value in the Value set.

---

## `×`

This means:

> Cartesian product
> “Pair of”

Example:

```
Add : Value × Value → Value
```

Reads as:

> Add is a function that takes two Values and returns a Value.

More explicitly:

```
Value × Value
```

means:

> All ordered pairs (a, b) where a is a Value and b is a Value.

So:

```
Add(a, b)
```

is defined for every pair of values.

---

# 5. Rewriting One Example in Plain English

When we write:

```
Add : Value × Value → Value
```

This means:

- The function Add accepts any two values from the language.
- It will always return a value from the language.
- It never fails.
- It never returns something outside the defined value system.

That single line encodes your **totality rule**.

---

# 6. How This Relates to Your Design

Your redesigned Liquid has:

- A closed set of values (`Value`)
- Total conversion functions (`Value → T`)
- Total operators (`Value × Value → Value`)

That’s a strong formal foundation.

You’re essentially saying:

> The template expression language is a closed algebra over Value.

That’s far more rigorous than legacy Liquid, which behaves more like a loosely documented scripting DSL.

---

If you'd like, next we can:

- Translate the full `+` definition into this formal notation cleanly,
- Or define the entire system without symbols (pure prose spec style),
- Or show how this formalism prevents accidental partiality creeping in later.

Where would you like to go next?

---

---

# 1. What does `⟦ e ⟧(ρ)` mean?

The brackets:

```
⟦ e ⟧
```

are called **semantic brackets** (or “denotation brackets”).

They mean:

> “the meaning of expression `e`”

So:

```
⟦ e ⟧
```

is not syntax anymore — it’s the _mathematical meaning_ of that syntax.

When we write:

```
⟦ e ⟧(ρ)
```

we are saying:

> Evaluate expression `e` in environment `ρ`.

This is standard notation in programming language semantics. It separates:

- `e` → the syntax (what the user wrote)
- `⟦ e ⟧` → the mathematical interpretation of that syntax

You can read it aloud as:

> “The meaning of e under rho”

---

# 2. What does `∈ EvalValue` mean here?

The full statement:

```
⟦ e ⟧(ρ) ∈ EvalValue
```

means:

> The result of evaluating expression `e` in environment `ρ` is a member of the set `EvalValue`.

In plain English:

> Evaluating any expression always produces either a data value or `Nothing`.

This is your **total evaluation guarantee**.

No crashes.
No undefined behavior.
No escaping the value system.

---

# 3. What Is an “Environment” (`ρ`)?

This is the important part.

An **environment** is just:

> A mapping from variable names to values.

Formally:

```
ρ : Identifier → DataValue
```

So if your template contains:

```
{{ user.name }}
```

Then `ρ` might be:

```
ρ = {
  "user" → { name: "Ada" }
}
```

The environment is:

- The current variable scope
- The current template context
- The current data bindings

It does _not_ include:

- Filters
- Operators
- Global semantics

Those belong to other structures (like `FilterEnv`).

---

# 4. Why We Write It This Way

When we define:

```
⟦ x ⟧(ρ) =
    if x ∈ dom(ρ)
        ρ(x)
    else
        Nothing
```

We’re defining variable lookup formally.

When we define:

```
⟦ a + b ⟧(ρ)
```

We mean:

1. Evaluate `a` under `ρ`
2. Evaluate `b` under `ρ`
3. Apply the `+` operator rule

So the evaluation function:

```
⟦ · ⟧
```

is the **core semantic function of your language**.

It converts:

```
Syntax  →  Meaning
```

given a particular environment.

---

# 5. Why Use `ρ`?

The Greek letter rho (`ρ`) is convention.

In formal semantics:

- `ρ` usually denotes environments
- `σ` sometimes denotes stores (mutable memory)
- `Γ` sometimes denotes typing environments

Since your language is immutable:

- You don’t need a mutable store
- Only an environment is required

So `ρ` is sufficient.

---

# 6. Concrete Example

Suppose:

```
ρ = {
  "x" → 10,
  "y" → 5
}
```

Expression:

```
x + y
```

Then:

```
⟦ x + y ⟧(ρ)
```

means:

1. ⟦ x ⟧(ρ) → 10
2. ⟦ y ⟧(ρ) → 5
3. Add(10, 5) → 15

So:

```
⟦ x + y ⟧(ρ) = 15
```

And since 15 ∈ DataValue:

```
⟦ x + y ⟧(ρ) ∈ EvalValue
```

Totality satisfied.

---

# 7. Example With Nothing

If:

```
ρ = { }
```

Expression:

```
x + 1
```

Then:

```
⟦ x ⟧(ρ) → Nothing
```

Propagation rule:

```
Add(Nothing, 1) → Nothing
```

So:

```
⟦ x + 1 ⟧(ρ) = Nothing
```

Still:

```
⟦ x + 1 ⟧(ρ) ∈ EvalValue
```

Totality still satisfied.

---

# 8. Big Picture

The statement:

```
⟦ e ⟧ : Environment → EvalValue
```

means:

> The evaluation function takes an environment and returns a value.

Or more explicitly:

> For any expression and any variable bindings, evaluation always produces a value in our algebra.

That is the formal backbone of your language.

---

# 9. Why This Matters for You

Because you want:

- Total evaluation
- No runtime failure
- Explicit `Nothing`
- Immutable data

Using this formal model lets you _prove_ properties like:

- Evaluation is deterministic
- Evaluation is total
- `Nothing` propagates uniformly
- Filters cannot escape the algebra

It’s not just academic notation — it lets you reason precisely about edge cases.
