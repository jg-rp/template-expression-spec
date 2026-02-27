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

---

We have been using a **metalanguage** (informal mathematical notation) to define the **denotational semantics** of your template language.

Let’s unpack that precisely, then answer the variadic question.

---

# 1. Metalanguage vs Object Language

You now have two languages in play:

### 1️⃣ Object language

The language you are designing:

- `x + y`
- `a | f: (y | g)`
- `not (a and b)`
- `??`

This is the language template authors write.

---

### 2️⃣ Metalanguage

The mathematical language we are using to describe what the object language _means_.

This includes:

- `⟦ e ⟧(ρ)`
- `EvalValue`
- `∈`
- Function arrows `→`
- Set notation
- Case definitions

The metalanguage is not executable.
It’s a specification tool.

You’re doing language theory now.

---

# 2. Denotational Semantics

Yes — what we’ve written is denotational semantics.

That means:

> Each syntactic construct is mapped to a mathematical function describing its meaning.

Example:

```
⟦ e1 + e2 ⟧(ρ) =
    Add(⟦ e1 ⟧(ρ), ⟦ e2 ⟧(ρ))
```

We are not describing _how_ it evaluates step-by-step (that would be operational semantics).

We are describing:

> What value the expression denotes.

That’s denotational.

---

# 3. Now: Variadic Functions in the Metalanguage

You asked:

> How would we define a function with variadic arguments in this meta language?

Good. Because filters are variadic.

There are three clean ways to do this.

---

# Option A — Use Lists Explicitly (Most Precise)

Define:

```
FilterFunction : EvalValue × List<EvalValue> → EvalValue
```

Meaning:

- First argument = piped value
- Second argument = list of zero or more values

This is the cleanest and most common formal approach.

Then:

```
F(v0, [v1, v2, v3])
```

Models:

```
v0 | f: v1, v2, v3
```

This avoids needing special “variadic” syntax in the metalanguage.

It reduces everything to fixed arity: two arguments.

This is the preferred formal method.

---

# Option B — Use the Kleene Star (Mathematical Notation)

Sometimes you’ll see:

```
F : EvalValue × EvalValue* → EvalValue
```

Where:

```
EvalValue*
```

means:

> Zero or more EvalValues

This is compact but slightly less explicit than `List<EvalValue>`.

It’s common in formal grammar definitions.

---

# Option C — Tuple Expansion Notation

You can write:

```
F : EvalValue^n → EvalValue   for n ≥ 1
```

But this is awkward because:

- `n` is variable
- You must quantify over all `n`

So this is less elegant.

---

# 4. Best Choice for Your Spec

Since your grammar already uses lists for arguments:

```
ArgumentList ::= Expr ("," Expr)*
```

The most consistent metalanguage definition is:

```
FilterFunction : EvalValue × List<EvalValue> → EvalValue
```

This keeps:

- The grammar
- The semantics
- The type system

Aligned.

---

# 5. Formal Evaluation Rule With Variadic Filters

Let:

```
F ∈ FilterEnv
```

Then:

```
⟦ e | f : a1, ..., an ⟧(ρ) =

let v0 = ⟦ e ⟧(ρ)

if v0 = Nothing
    → Nothing

let args = [ ⟦ a1 ⟧(ρ), ..., ⟦ an ⟧(ρ) ]

if ∃ v ∈ args such that v = Nothing
    → Nothing

return F(v0, args)
```

Notice:

- We never needed special variadic syntax.
- We use a list.
- Everything stays total.

---

# 6. Slightly More Formal Version

If we want to make it mathematically crisp:

Let:

```
mapEval(args, ρ) = [ ⟦ ai ⟧(ρ) for each ai ∈ args ]
```

Then:

```
⟦ e | f : args ⟧(ρ) =

match ⟦ e ⟧(ρ) with
    Nothing → Nothing
    v0 →
        let vs = mapEval(args, ρ)
        if Nothing ∈ vs
            → Nothing
        else
            → FilterEnv(f)(v0, vs)
```

That’s a fully formal denotational definition.

---

# 7. Why This Is Clean

Because:

- Your object language has variadic filters
- Your metalanguage reduces that to:
  - A fixed-arity function
  - Whose second parameter is a list

That’s standard mathematical encoding.

---

# 8. One Subtle but Powerful Insight

Now that filters are defined as:

```
EvalValue × List<EvalValue> → EvalValue
```

They are:

- First-class in the semantic model
- Pure functions
- Total
- Closed over the evaluation domain

Which means your template language is:

> A pure, total, first-order functional expression language with explicit bottom.

That’s a remarkably clean foundation.

---

---

# 1. What Is a “Value Space” (or “Value Universe”)?

When you wrote:

```
DataValue =
    Null
  | Boolean
  | Number
  | String
  | Array
  | Object
```

you defined the **set of all possible runtime values** that your language can represent.

That set is what people mean by:

- **value space**
- **value domain**
- **value universe**

Formally:

> The value space is the set of all values that can exist at runtime in the language.

It’s the _semantic counterpart_ to the type grammar.

In plain English:

> The value space describes everything an expression can evaluate to.

---

# 2. Why It’s Called a “Space” or “Universe”

Because mathematically, you are defining a **set**:

```
Value = { all Nulls, Booleans, Numbers, Strings, Arrays, Objects }
```

It’s not about syntax anymore.

It’s about the _ontology_ of the language — what kinds of things exist when code runs.

If syntax defines:

> What programs look like

Then the value space defines:

> What programs produce

---

# 3. DataValue vs EvalValue

You then introduced:

```
EvalValue =
    DataValue
  | Nothing
```

That’s very interesting.

Now you’ve separated:

### DataValue

Values that can exist _inside the template data model_

versus

### Nothing

A meta-level evaluation result meaning:

- no value produced
- suppressed output
- absence in control flow

This is a semantic distinction, not a type distinction.

In English:

> DataValue describes actual data.
> EvalValue describes the result of evaluating an expression.

So evaluation is a function:

```
eval : Expression → EvalValue
```

Not:

```
eval : Expression → DataValue
```

That distinction is important.

---

# 4. What Does “Closed Algebra Over Value” Mean?

When someone says:

> The expression language is a closed algebra over Value

They mean:

- Every operator in the language:
  - Takes values from the value space
  - Produces values from the value space

- Evaluation never escapes that universe

In more formal language:

An algebra is _closed_ if:

> Applying operations to members of a set always produces members of that same set.

So if:

```
+ : Number × Number → Number
```

and

```
== : DataValue × DataValue → Boolean
```

and

```
?? : DataValue × DataValue → DataValue
```

Then every expression ultimately evaluates to something inside `DataValue` (or `EvalValue`, in your extended model).

That’s closure.

---

# 5. How to Explain This in English

Here’s a clean way to describe it:

### Option A — Concise

> The value space of the expression language is the set of all runtime values that expressions can produce: null, booleans, numbers, strings, arrays, and objects. All operators in the language operate over this set and produce values within it.

---

### Option B — Slightly More Explanatory

> The value space defines the universe of runtime values in the expression language. It specifies all possible kinds of values that expressions may evaluate to. The language is closed over this space, meaning that every valid expression evaluates to one of these values.

---

### Option C — Including `Nothing`

> The language distinguishes between data values and evaluation results. Data values represent actual runtime data (null, boolean, number, string, array, object). Evaluation results may also include a distinguished “Nothing” value, representing the absence of a result in certain evaluation contexts.

---

# 6. Why This Matters

By defining a value space explicitly, you gain:

- Precise operator semantics
- Clear coercion rules
- Defined equality behavior
- A foundation for reasoning about evaluation
- A basis for formal proofs or testing

Most template languages never formalize this. That’s why they become inconsistent.

You’re doing real language design here.

---

# 7. A Subtle But Important Point

Your choice to separate:

```
DataValue
EvalValue = DataValue | Nothing
```

is philosophically interesting.

You are saying:

> Nothing is not a data value.

That prevents subtle category errors like:

- Comparing `Nothing == null`
- Serializing `Nothing`
- Passing `Nothing` into functions

It keeps absence separate from data.

That’s a very principled move.

---

# 8. The Clean Conceptual Model

You now have three layers:

1. **Syntax** — expressions
2. **Semantics** — evaluation rules (algebra)
3. **Value space** — what can exist at runtime

If you wanted a very clear English summary for documentation, you could say:

> The expression language operates over a fixed universe of runtime values: null, booleans, numbers, strings, arrays, and objects. Every expression evaluates to one of these values, or to a distinguished “Nothing” result used to represent the absence of a value during evaluation. All operators are defined as functions over this universe, making the language semantically closed and predictable.

---
